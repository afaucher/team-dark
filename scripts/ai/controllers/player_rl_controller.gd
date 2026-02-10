extends "res://addons/godot_rl_agents/controller/ai_controller_2d.gd"

# --- Interface expected by Player ---
var move_vector: Vector2 = Vector2.ZERO
var aim_vector: Vector2 = Vector2.ZERO
var fire_just_pressed: Array[bool] = [false, false, false]
var fire_held: Array[bool] = [false, false, false]
var fire_all_just: bool = false
var fire_all_held: bool = false
# ------------------------------------

var RaycastSensorClass = load("res://addons/godot_rl_agents/sensors/sensors_2d/RaycastSensor2D.gd")

var sensors: Array = []
var player: Node = null

var prev_dist_to_target: float = 0.0
var prev_gems: int = 0
var prev_health: float = 100.0
var game_manager: Node = null

var last_reward_pos: Vector2 = Vector2.ZERO
var stagnation_ticks: int = 0
var episode_kills: int = 0
var episode_damage: float = 0.0
var episode_distance: float = 0.0
var episode_shots: int = 0
var episode_damage_taken: float = 0.0
var episode_deaths: int = 0
var episode_pickups: int = 0
var last_pos_for_dist: Vector2 = Vector2.ZERO

# Debug Visuals
var _last_path: PackedVector2Array = []
var _next_node_pos: Vector2 = Vector2.ZERO
var _target_world_pos: Vector2 = Vector2.ZERO
var _target_is_blocked: bool = false

func _ready():
	super._ready()
	player = get_parent()
	
	# Find Game Manager
	game_manager = get_tree().root.find_child("GameManager", true, false)
	if not game_manager:
		game_manager = get_tree().root.find_child("Game", true, false)
	if not game_manager:
		game_manager = get_tree().root.find_child("TrainingManager", true, false)
		
	# Initialize state
	prev_dist_to_target = clamp(_get_mission_target_vec().length(), 0.0, 50000.0)
	if game_manager:
		prev_gems = game_manager.collected_gems
	
	# Create sensors dynamically
	_create_sensor("World", 1, 16, 1000.0) 
	_create_sector_sensor("Enemy", 4, 16, 1000.0) 
	_create_sensor("Pickup", 16, 16, 1000.0) 

func _create_sensor(name: String, mask: int, rays: int, length: float):
	var sensor = RaycastSensorClass.new()
	sensor.name = name + "Sensor"
	sensor.collision_mask = mask
	sensor.n_rays = rays
	sensor.ray_length = length
	sensor.debug_draw = true 
	add_child(sensor)
	sensors.append(sensor)

func _create_sector_sensor(name: String, mask: int, sectors: int, length: float):
	var sensor_script = load("res://scripts/ai/sensors/sector_sensor_2d.gd")
	var sensor = sensor_script.new()
	sensor.name = name + "SectorSensor"
	sensor.collision_mask = mask
	sensor.n_sectors = sectors
	sensor.max_range = length
	sensor.debug_draw = true
	add_child(sensor)
	sensors.append(sensor)

func _physics_process(delta: float):
	if needs_reset:
		reset()
	super._physics_process(delta)
	if DebugManager.show_debug:
		queue_redraw()

func _draw():
	if not DebugManager.show_debug or not player:
		return
		
	var my_pos = Vector2.ZERO # Local space of controller (parented to player)
	
	# 1. Draw Final Target (Dashed Magenta)
	if _target_world_pos != Vector2.ZERO:
		var target_local = player.to_local(_target_world_pos)
		draw_line(my_pos, target_local, Color(1, 0, 1, 0.4), 2.0)
		draw_circle(target_local, 15.0, Color(1, 0, 1, 0.6))
		
	# 2. Draw A* Path (Yellow)
	if _last_path.size() > 0:
		var pts = []
		for p in _last_path:
			pts.append(player.to_local(p))
		
		for i in range(pts.size() - 1):
			draw_line(pts[i], pts[i+1], Color.YELLOW, 4.0)
			
	# 3. Draw Next Node (Bright Orange Arrow/Line)
	if _next_node_pos != Vector2.ZERO:
		var node_local = player.to_local(_next_node_pos)
		draw_line(my_pos, node_local, Color.ORANGE, 8.0)
		draw_circle(node_local, 10.0, Color.ORANGE)
		
	# 4. Blocked Status
	if _target_is_blocked:
		draw_string(ThemeDB.fallback_font, my_pos + Vector2(-40, -60), "PATH BLOCKED", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.RED)

func _safe(val: float) -> float:
	if is_nan(val) or is_inf(val):
		return 0.0
	return val

func get_obs() -> Dictionary:
	var obs = []
	
	# --- GROUP 1: SPATIAL (48 Dim: 0-47) ---
	for sensor in sensors:
		obs.append_array(sensor.get_observation())
	
	if player:
		var current_gems = game_manager.collected_gems if game_manager else 0
		var max_gems = game_manager.MAX_GEMS if game_manager else 10
		
		# --- GROUP 2: SELF-STATUS (9 Dim: 48-56) ---
		obs.append(clamp(player.current_hp / 100.0, 0.0, 1.0) if "current_hp" in player else 1.0) # 48
		obs.append(float(current_gems) / float(max_gems)) # 49
		obs.append(sin(player.rotation)) # 50
		obs.append(cos(player.rotation)) # 51
		obs.append(player.velocity.x / 1000.0) # 52
		obs.append(player.velocity.y / 1000.0) # 53
		obs.append(clamp(player.angular_velocity / 10.0, -1.0, 1.0) if "angular_velocity" in player else 0.0) # 54
		obs.append(1.0 if current_gems >= max_gems else 0.0) # 55: Extraction Ready
		
		var enemies = get_tree().get_nodes_in_group("enemies")
		var min_enemy_dist = 2000.0
		var aiming_at_me = 0.0
		for e in enemies:
			if e.is_queued_for_deletion(): continue
			var dist = player.global_position.distance_to(e.global_position)
			if dist < min_enemy_dist: min_enemy_dist = dist
			var diff = player.global_position - e.global_position
			var to_player = diff.normalized() if diff.length() > 0.01 else Vector2.ZERO
			var e_dir = Vector2.RIGHT.rotated(e.rotation)
			if dist < 800.0 and e_dir.dot(to_player) > 0.96: aiming_at_me = 1.0
		obs.append(clamp(min_enemy_dist / 1000.0, 0.0, 1.0)) # 56
		
		# --- GROUP 3: MISSION TARGET (4 Dim: 57-60) ---
		var mission_vec = _get_mission_target_vec()
		var target_angle = mission_vec.angle()
		var rel_target_angle = wrapf(target_angle - player.rotation, -PI, PI) / PI
		obs.append(mission_vec.x / 10000.0) # 57
		obs.append(mission_vec.y / 10000.0) # 58
		obs.append(clamp(mission_vec.length() / 15000.0, 0.0, 1.0)) # 59
		obs.append(rel_target_angle) # 60
		
		# --- GROUP 4: PATH GUIDANCE (5 Dim: 61-65) ---
		var next_node_vec = Vector2.ZERO
		var target_blocked = 0.0
		var path_dist = 0.0
		var rel_node_angle = 0.0
		
		_target_world_pos = player.global_position + mission_vec
		_last_path = PackedVector2Array()
		_next_node_pos = Vector2.ZERO
		_target_is_blocked = false

		if game_manager and "pathfinding" in game_manager and game_manager.pathfinding:
			var path = game_manager.pathfinding.get_path_to_world_pos(player.global_position, _target_world_pos)
			_last_path = path
			if path.size() > 1:
				_next_node_pos = path[1]
				next_node_vec = (_next_node_pos - player.global_position).normalized()
				var pos_to_node = _next_node_pos - player.global_position
				rel_node_angle = wrapf(pos_to_node.angle() - player.rotation, -PI, PI) / PI
				path_dist = path.size() * 128.0
				var space_state = get_world_2d().direct_space_state
				var query = PhysicsRayQueryParameters2D.create(player.global_position, _target_world_pos)
				query.collision_mask = 1
				if space_state.intersect_ray(query): 
					target_blocked = 1.0
					_target_is_blocked = true
		obs.append(next_node_vec.x) # 61
		obs.append(next_node_vec.y) # 62
		obs.append(target_blocked)  # 63
		obs.append(clamp(path_dist / 15000.0, 0.0, 1.0)) # 64
		obs.append(rel_node_angle)  # 65

		# --- GROUP 5: GEAR GUIDANCE (5 Dim: 66-70) ---
		var gear_vec = _get_vector_to_nearest_gear()
		var gear_angle = gear_vec.angle()
		var rel_gear_angle = wrapf(gear_angle - player.rotation, -PI, PI) / PI
		obs.append(gear_vec.x / 10000.0) # 66
		obs.append(gear_vec.y / 10000.0) # 67
		obs.append(clamp(gear_vec.length() / 15000.0, 0.0, 1.0)) # 68
		obs.append(rel_gear_angle) # 69
		var nearest_p = _get_nearest_pickup_node()
		var p_type = 0.0
		if nearest_p:
			var t = nearest_p.get("pickup_type") if "pickup_type" in nearest_p else "gem"
			if t == "gem": p_type = 0.3
			elif t == "weapon": p_type = 0.6
			elif t == "utility" or t == "health": p_type = 1.0
		obs.append(p_type) # 70
		
		# --- GROUP 6: THREATS (13 Dim: 71-83) ---
		obs.append(aiming_at_me) # 71
		var projs = get_tree().get_nodes_in_group("projectiles")
		var sorted_projs = []
		for p in projs:
			if p.is_queued_for_deletion(): continue
			if "attacker_id" in p and p.attacker_id == player.player_id: continue
			var d = player.global_position.distance_to(p.global_position)
			if d < 1200.0: sorted_projs.append({"node": p, "dist": d})
		sorted_projs.sort_custom(func(a, b): return a.dist < b.dist)
		for i in range(3):
			if i < sorted_projs.size():
				var pnode = sorted_projs[i].node
				var rel_pos = pnode.global_position - player.global_position
				var vel = Vector2.RIGHT.rotated(pnode.rotation) * pnode.speed
				obs.append(rel_pos.x / 1200.0)
				obs.append(rel_pos.y / 1200.0)
				obs.append(vel.x / 1000.0)
				obs.append(vel.y / 1000.0)
			else:
				for j in range(4): obs.append(0.0)
				
		# --- GROUP 7: ARSENAL (12 Dim: 84-95) ---
		for i in range(3): # Fixed 3 mounts
			var mount = player.mounts[i] if player.get("mounts") and player.mounts.size() > i else null
			if mount and mount.get_child_count() > 0:
				var weapon = mount.get_child(0)
				obs.append(1.0 if ("can_fire" in weapon and weapon.can_fire) else 0.5)
				var cd = 1.0
				if "_timer" in weapon and weapon._timer:
					var timer = weapon._timer
					cd = 1.0 - (timer.time_left / timer.wait_time) if timer.time_left > 0 and timer.wait_time > 0 else 1.0
				obs.append(cd)
				var w_name = weapon.get("weapon_name") if "weapon_name" in weapon else ""
				var w_type = 0.0
				if "Pellet" in w_name: w_type = 0.2
				elif "Machine" in w_name: w_type = 0.4
				elif "Shotgun" in w_name: w_type = 0.6
				elif "Grenade" in w_name: w_type = 0.8
				elif w_name != "": w_type = 1.0
				obs.append(w_type)
				obs.append(1.0) # Ammo
			else:
				for j in range(4): obs.append(0.0)
		
		# --- GROUP 8: PADDING (6 Dim: 96-101) ---
		for i in range(6): obs.append(0.0)
				
	else:
		for i in range(54): obs.append(0.0)

	for i in range(obs.size()):
		obs[i] = _safe(obs[i])
	return {"obs": obs}

func get_info() -> Dictionary:
	var current_gems = game_manager.collected_gems if game_manager else 0
	var mission_vec = _get_mission_target_vec()
	var target_dist = mission_vec.length() if mission_vec.length_squared() < 1e18 else 99999.0
	return {
		"is_success": _safe(1.0 if (current_gems >= 10 and target_dist < 100.0) else 0.0),
		"gems_collected": _safe(float(current_gems)),
		"enemies_killed": _safe(float(episode_kills)),
		"damage_dealt": _safe(episode_damage),
		"damage_taken": _safe(episode_damage_taken),
		"distance_travelled": _safe(episode_distance),
		"shots_fired": _safe(float(episode_shots)),
		"pickups_collected": _safe(float(episode_pickups)),
		"deaths": _safe(float(episode_deaths)),
		"is_dead": _safe(1.0 if (player and "health" in player and player.health <= 0) else 0.0)
	}

func _get_mission_target_vec() -> Vector2:
	if not player: return Vector2.ZERO
	var current_gems = game_manager.collected_gems if game_manager else 0
	var max_gems = game_manager.MAX_GEMS if game_manager else 10
	
	if current_gems >= max_gems:
		var extractions = get_tree().get_nodes_in_group("extraction")
		if extractions.size() > 0: return (extractions[0].global_position - player.global_position)
	
	var gems = get_tree().get_nodes_in_group("gems")
	var nearest_dist = INF
	var nearest_target = null
	for gem in gems:
		if gem.is_queued_for_deletion(): continue
		var d = player.global_position.distance_to(gem.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_target = gem
	
	if nearest_target: return (nearest_target.global_position - player.global_position)
	return Vector2.ZERO

func _get_vector_to_nearest_gear() -> Vector2:
	if not player: return Vector2.ZERO
	var pickups = get_tree().get_nodes_in_group("pickups")
	var nearest_dist = INF
	var nearest_target = null
	for p in pickups:
		if p.is_queued_for_deletion() or ("pickup_type" in p and p.pickup_type == "gem"): continue
		var d = player.global_position.distance_to(p.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_target = p
	if nearest_target: return (nearest_target.global_position - player.global_position)
	return Vector2.ZERO

func _get_nearest_pickup_node() -> Node:
	if not player: return null
	var pickups = get_tree().get_nodes_in_group("pickups")
	var nearest_dist = INF
	var nearest = null
	for p in pickups:
		if p.is_queued_for_deletion(): continue
		var d = player.global_position.distance_to(p.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = p
	return nearest

var current_step: int = 0
const MAX_STEPS: int = 20000 

func get_reward() -> float:
	current_step += 1
	var r = -0.001 
	var mission_vec = _get_mission_target_vec()
	var curr_dist = clamp(mission_vec.length(), 0.0, 50000.0)
	if not is_inf(prev_dist_to_target) and not is_nan(prev_dist_to_target):
		r += (prev_dist_to_target - curr_dist) * 0.01
	prev_dist_to_target = curr_dist
	if game_manager:
		var curr_gems = game_manager.collected_gems
		if curr_gems > prev_gems:
			r += 200.0
			prev_dist_to_target = clamp(_get_mission_target_vec().length(), 0.0, 50000.0)
		prev_gems = curr_gems
		if curr_gems >= game_manager.MAX_GEMS:
			r += 0.01
			if curr_dist < 100.0:
				r += 500.0
				done = true 
	if player and "health" in player:
		if player.health < prev_health:
			r -= 5.0
			episode_damage_taken += (prev_health - player.health)
		elif player.health > prev_health:
			r += (player.health - prev_health) * 0.5 # Reward for healing
		prev_health = player.health
		if player.health <= 0:
			episode_deaths = 1
			r -= 100.0
			done = true
	if game_manager and game_manager.has_method("consume_combat_metrics"):
		var metrics = game_manager.consume_combat_metrics(player.player_id if player else 1)
		r += metrics.damage * 0.1
		episode_damage += metrics.damage
		if metrics.kills > 0:
			r += metrics.kills * 10.0
			episode_kills += metrics.kills
		if metrics.get("pickups", 0) > 0:
			r += metrics.pickups * 10.0
			episode_pickups += metrics.pickups
	if player:
		episode_distance += player.global_position.distance_to(last_pos_for_dist)
		last_pos_for_dist = player.global_position
		if player.global_position.distance_to(last_reward_pos) < 5.0:
			stagnation_ticks += 1
		else:
			stagnation_ticks = 0
			last_reward_pos = player.global_position
		if stagnation_ticks > 60: r -= 0.1
	if fire_all_just:
		episode_shots += 1
		r -= 0.01
	for i in range(3):
		if fire_just_pressed[i]:
			episode_shots += 1
			r -= 0.01
	if current_step >= MAX_STEPS:
		done = true
		r -= 5.0 
	return _safe(r)

func reset():
	super.reset()
	done = false
	current_step = 0
	episode_kills = 0
	episode_damage = 0.0
	episode_distance = 0.0
	episode_shots = 0
	episode_damage_taken = 0.0
	episode_deaths = 0
	episode_pickups = 0
	last_pos_for_dist = player.global_position if player else Vector2.ZERO
	if game_manager and game_manager.has_method("reset_level"):
		game_manager.reset_level()
	prev_dist_to_target = clamp(_get_mission_target_vec().length(), 0.0, 50000.0)
	if game_manager:
		prev_gems = game_manager.collected_gems
		prev_health = player.health if (player and "health" in player) else 100.0

func get_action_space() -> Dictionary:
	return {
		"move": {"size": 2, "action_type": "continuous"},
		"aim": {"size": 2, "action_type": "continuous"},
		"shoot": {"size": 1, "action_type": "discrete"},
	}

func set_action(action) -> void:
	if "move" in action:
		move_vector.x = clamp(action["move"][0], -1.0, 1.0)
		move_vector.y = clamp(action["move"][1], -1.0, 1.0)
	if "aim" in action:
		aim_vector.x = clamp(action["aim"][0], -1.0, 1.0)
		aim_vector.y = clamp(action["aim"][1], -1.0, 1.0)
	if "shoot" in action:
		fire_all_held = action["shoot"] > 0
		fire_all_just = action["shoot"] > 0
