extends CharacterBody2D

const DuckNameGenerator = preload("res://scripts/duck_names.gd")

const SPEED = 600.0
const ACCEL = 2500.0
const FRICTION = 2000.0
const ROTATION_SPEED = 15.0 # rad/s for smoothing

@export var player_id: int = 1:
	set(id):
		player_id = id
		set_multiplayer_authority(id)
		# Check if node exists before accessing (setter can be called before _ready)
		if has_node("MultiplayerSynchronizer"):
			$MultiplayerSynchronizer.set_multiplayer_authority(id)

@export var player_name: String = ""
@export var default_weapon_scene: PackedScene
@onready var mounts = [$MountLeft, $MountRight, $MountFront]
var last_rotation: float = 0.0
var angular_velocity: float = 0.0 # rad/s
@onready var name_label = get_node_or_null("NameLabel")

# Pickup System
const PICKUP_HOLD_DURATION = 0.5
const PICKUP_RANGE = 100.0
var mount_hold_times = [0.0, 0.0, 0.0] # Left, Right, Front
var current_mount_weapons = [null, null, null] # PackedScenes for dropping
var nearest_pickup = null

# AI System
enum AIMode { MANUAL, HARDCODED, TRAINED }
@export var ai_mode: AIMode = AIMode.MANUAL:
	set(val):
		ai_mode = val
		_update_ai_controller()

var ai_controller: Node = null

# Input Buffers (Shared between Manual and AI)
var move_input: Vector2 = Vector2.ZERO
var aim_input: Vector2 = Vector2.ZERO
var fire_just_pressed: Array[bool] = [false, false, false]
var fire_held: Array[bool] = [false, false, false]
var fire_all_just: bool = false
var fire_all_held: bool = false

func _ready():
	print("Player script loaded for ID: ", player_id, " (Authority: ", is_multiplayer_authority(), ")")
	# Set authority on the Player node itself (controls processing)
	set_multiplayer_authority(player_id)
	
	if is_multiplayer_authority():
		# Generate or assign name
		if player_name == "":
			player_name = DuckNameGenerator.generate_name()
		print("Assigned name: ", player_name)
	
	if name_label:
		name_label.text = player_name
		name_label.modulate.a = 0.0 # Hidden by default
	
	var sync_node = get_node_or_null("MultiplayerSynchronizer")
	if sync_node:
		sync_node.set_multiplayer_authority(player_id)
	else:
		print("CRITICAL ERROR: MultiplayerSynchronizer missing in Player scene!")

	# Only enable camera for the local player
	var cam = get_node_or_null("Camera2D")
	if cam:
		cam.enabled = is_multiplayer_authority()
		if cam.enabled:
			cam.make_current() # Force it to be the active camera
			print("Camera enabled and made current for Player ", player_id)
	else:
		print("CRITICAL ERROR: Camera2D missing in Player scene!")

	if not default_weapon_scene:
		default_weapon_scene = load("res://scenes/weapons/pellet_gun.tscn")

	if default_weapon_scene:
		equip_weapon(0, "") # Clear Left
		equip_weapon(1, "") # Clear Right
		equip_weapon(2, "res://scenes/weapons/pellet_gun.tscn") # Front mount
	else:
		print("ERROR: No default weapon scene found!")

	_update_ai_controller()

func _update_ai_controller():
	if ai_controller:
		ai_controller.queue_free()
		ai_controller = null
		
	match ai_mode:
		AIMode.HARDCODED:
			# We'll implement PlayerAutoplayController later
			var script = load("res://scripts/ai/controllers/player_autoplay_controller.gd")
			if script:
				ai_controller = Node.new()
				ai_controller.set_script(script)
				add_child(ai_controller)
		AIMode.TRAINED:
			# For Godot RL Agents
			pass

@rpc("any_peer", "call_local", "reliable")
func equip_weapon(mount_index: int, weapon_path: String = ""):
	if mount_index < 0 or mount_index >= mounts.size():
		return
	
	var weapon_packed_scene = load(weapon_path) if weapon_path != "" else null
	
	var mount = mounts[mount_index]
	# Remove existing children (weapons)
	for child in mount.get_children():
		child.queue_free()
	
	var w_name = "Empty"
	var status = "-"
	
	current_mount_weapons[mount_index] = weapon_packed_scene
	
	if weapon_packed_scene:
		# Add new weapon
		var weapon = weapon_packed_scene.instantiate()
		mount.add_child(weapon)
		w_name = weapon.weapon_name if "weapon_name" in weapon else "Unknown"
		status = "READY"
	
	# Update HUD for local player
	if is_multiplayer_authority():
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.update_mount(mount_index, w_name, status)
			if hud.has_method("update_weapon_status"):
				hud.update_weapon_status(mount_index, true, 1.0)
	
	queue_redraw()

func drop_weapon(mount_index: int):
	if not multiplayer.is_server():
		return
		
	var weapon_scene = current_mount_weapons[mount_index]
	if not weapon_scene:
		return
		
	# Spawn a pickup node and set its scene to this weapon
	var pickup_script = load("res://scripts/pickups/pickup.gd")
	var pickup = Area2D.new()
	pickup.set_script(pickup_script)
	pickup.pickup_type = "weapon"
	pickup.item_scene = weapon_scene
	
	# Get name from a temporary instance
	var temp = weapon_scene.instantiate()
	if "utility_name" in temp:
		pickup.pickup_name = temp.utility_name
	else:
		pickup.pickup_name = temp.weapon_name if "weapon_name" in temp else "Weapon"
	temp.free()
	
	pickup.global_position = global_position + Vector2.from_angle(randf() * TAU) * 50.0
	get_tree().current_scene.add_child(pickup, true)
	
	# Clear the mount
	equip_weapon.rpc(mount_index, "")

func swap_weapon(mount_index: int, new_weapon_path: String):
	if not multiplayer.is_server():
		return
		
	# 1. Drop the current weapon if it exists
	var old_weapon_scene = current_mount_weapons[mount_index]
	if old_weapon_scene:
		var pickup_pkg = load("res://scenes/objects/pickup.tscn")
		var pickup = pickup_pkg.instantiate()
		pickup.pickup_type = "weapon"
		pickup.item_scene = old_weapon_scene
		pickup.item_scene_path = old_weapon_scene.resource_path
		
		# Get name
		var temp = old_weapon_scene.instantiate()
		if "utility_name" in temp:
			pickup.pickup_name = temp.utility_name
		else:
			pickup.pickup_name = temp.weapon_name if "weapon_name" in temp else "Dropped Weapon"
		temp.free()
		
		# Spawn behind the player
		pickup.global_position = global_position - Vector2.from_angle(rotation) * 60.0
		get_tree().current_scene.find_child("Pickups", true, false).add_child(pickup, true)
		print("[Server] Player ", player_id, " dropped ", pickup.pickup_name)
	
	# 2. Equip the new weapon
	equip_weapon.rpc(mount_index, new_weapon_path)

func heal(amount: float):
	current_hp = min(current_hp + amount, max_hp)
	print("Player ", player_id, " healed by ", amount, ". HP: ", current_hp)
	_update_health_hud()

func add_ammo(amount: int):
	print("Player ", player_id, " received ", amount, " ammo.")
	# TODO: Implement ammo system in weapons

func _physics_process(delta):
	if is_multiplayer_authority():
		if not is_dead:
			_gather_inputs(delta)
			_apply_actions(delta)
	
	if not is_dead:
		move_and_slide()

func _gather_inputs(delta):
	if ai_mode == AIMode.MANUAL:
		move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		# Hybrid Aiming: Stick/Keyboard vs Mouse
		var stick_input = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
		if stick_input.length() > 0.1:
			aim_input = stick_input
		else:
			# If no stick input, point towards mouse
			var mouse_pos = get_global_mouse_position()
			aim_input = (mouse_pos - global_position).normalized()
		
		fire_just_pressed[0] = Input.is_action_just_pressed("fire_left")
		fire_held[0] = Input.is_action_pressed("fire_left")
		fire_just_pressed[1] = Input.is_action_just_pressed("fire_right")
		fire_held[1] = Input.is_action_pressed("fire_right")
		fire_just_pressed[2] = Input.is_action_just_pressed("fire_front")
		fire_held[2] = Input.is_action_pressed("fire_front")
		
		fire_all_just = Input.is_action_just_pressed("fire_all")
		fire_all_held = Input.is_action_pressed("fire_all")
	elif ai_controller:
		ai_controller.update_actions(delta)
		move_input = ai_controller.move_vector
		aim_input = ai_controller.aim_vector
		fire_just_pressed = ai_controller.fire_just_pressed
		fire_held = ai_controller.fire_held
		fire_all_just = ai_controller.fire_all_just
		fire_all_held = ai_controller.fire_all_held

func _apply_actions(delta):
	if move_input:
		velocity = velocity.move_toward(move_input * SPEED, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	if aim_input.length() > 0.1:
		var target_rot = aim_input.angle()
		rotation = lerp_angle(rotation, target_rot, delta * ROTATION_SPEED)
	
	# Track angular velocity (rad/s)
	angular_velocity = (rotation - last_rotation) / delta
	last_rotation = rotation
	
	# Firing
	for i in range(3):
		if fire_just_pressed[i] or fire_held[i]:
			_fire_mount(i, fire_just_pressed[i], fire_held[i])
			
	if fire_all_just or fire_all_held:
		for i in range(3):
			var weapon = current_mount_weapons[i]
			if weapon:
				var temp = weapon.instantiate()
				var is_passive = "is_passive" in temp and temp.is_passive
				temp.free()
				if is_passive:
					continue
			_fire_mount(i, fire_all_just, fire_all_held)

	_handle_pickup_timers(delta)

func _handle_pickup_timers(delta):
	var actions_pressed = [false, false, false]
	if ai_mode == AIMode.MANUAL:
		actions_pressed[0] = Input.is_action_pressed("fire_left")
		actions_pressed[1] = Input.is_action_pressed("fire_right")
		actions_pressed[2] = Input.is_action_pressed("fire_front")
	else:
		actions_pressed = fire_held
		
	# Auto-pickup Gems if very close
	if nearest_pickup and nearest_pickup.pickup_type == "gem":
		var dist = global_position.distance_to(nearest_pickup.global_position)
		if dist < 120.0: # Increased range slightly for safety
			if multiplayer.is_server():
				print("[Player] Auto-picking gem at dist: ", dist)
			_request_pickup(nearest_pickup.get_path(), 2) # Front mount as default
			return

	for i in range(3):
		if actions_pressed[i] and nearest_pickup:
			mount_hold_times[i] += delta
			if mount_hold_times[i] >= PICKUP_HOLD_DURATION:
				_request_pickup(nearest_pickup.get_path(), i)
				mount_hold_times[i] = -1.0 # Prevent multiple triggers
		elif !actions_pressed[i]:
			mount_hold_times[i] = 0.0

func _request_pickup(pickup_path: NodePath, mount_index: int):
	# Request server to perform pickup
	_srv_pickup.rpc_id(1, pickup_path, mount_index)

@rpc("any_peer", "call_local")
func _srv_pickup(pickup_path: NodePath, mount_index: int):
	if not multiplayer.is_server(): return
	
	var pickup = get_node_or_null(pickup_path)
	if pickup and pickup.has_method("pickup_collected"):
		if pickup.pickup_type == "weapon" and pickup.item_scene_path != "":
			swap_weapon(mount_index, pickup.item_scene_path)
			pickup.queue_free()
		elif pickup.pickup_type == "health":
			# New: Health kits can now be mounted!
			# We'll use a special scene for the mounted health kit
			swap_weapon(mount_index, "res://scenes/objects/health_kit_mounted.tscn")
			pickup.queue_free()
		else:
			# Regular pickup (ammo, etc)
			pickup.pickup_collected(player_id, mount_index)

func _update_nearest_pickup():
	var pickups = get_tree().get_nodes_in_group("pickups")
	var best_dist = PICKUP_RANGE
	var best_pickup = null
	
	for p in pickups:
		var d = global_position.distance_to(p.global_position)
		if d < best_dist:
			best_dist = d
			best_pickup = p
	
	nearest_pickup = best_pickup

func _fire_mount(index: int, just_pressed: bool, held: bool):
	if index < 0 or index >= mounts.size():
		return
	
	# Don't fire if we just picked something up or are holding for pickup
	if mount_hold_times[index] < 0 or mount_hold_times[index] > 0.1:
		return

	var mount = mounts[index]
	if mount.get_child_count() > 0:
		var weapon = mount.get_child(0)
		if weapon.has_method("trigger"):
			weapon.trigger(just_pressed, held)

func _input(event):
	if is_dead: return

	if event.is_action_pressed("toggle_debug"):
		queue_redraw()


func _draw():
	# Neon Vector Style via Procedural Glow
	var radius = 32.0
	# HDR Color boost (Values > 1.0 trigger strong glow)
	var color_hdr = Color(0.0, 3.0, 3.0, 1.0) # Bright Cyan (Boosted G/B)
	var color_base = Color("#00fff5")
	
	# 0. Mountpoint Indicators (Drawn FIRST so they are "under" the body)
	var mount_color = Color(3.0, 0.0, 0.8, 1.0) # HDR Red/Pink
	for m in mounts:
		if m and m.get_child_count() > 0:
			# Glow backing
			draw_circle(m.position, 8.0, mount_color * Color(1,1,1,0.3)) 
			draw_circle(m.position, 5.0, Color.BLACK)
			draw_circle(m.position, 3.0, mount_color)
			# Connection line (Under body)
			draw_line(Vector2.ZERO, m.position, mount_color.darkened(0.5), 2.0)

	# 1. "Farther" Glow Halo (Simulated by large faint circle)
	for i in range(5):
		var halo_radius = radius + (i * 10.0) + 10.0
		var alpha = 0.1 - (i * 0.02)
		draw_circle(Vector2.ZERO, halo_radius, color_base * Color(1, 1, 1, alpha))

	# 2. Main Hollow Ring (Thick & Bright)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, color_hdr, 6.0, true)
	
	# 3. Inner Black Fill (to cover map lines below)
	draw_circle(Vector2.ZERO, radius - 3, Color.BLACK)
	
	# 4. Inner "Core" Ring (Thin, blinding white for extra pop)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(2, 2, 2, 1), 2.0, true)
	
	# Directional indicator (Wide arc further inside the body)
	var indicator_radius = radius - 10.0
	var arc_width = 3.0
	var angle_span = deg_to_rad(45.0) # 3x wider than previous 15 deg
	draw_arc(Vector2.ZERO, indicator_radius, -angle_span/2, angle_span/2, 32, color_hdr, arc_width, true)

	# Pickup Progress
	for i in range(3):
		if mount_hold_times[i] > PICKUP_HOLD_DURATION * 0.5:
			# Scale progress so it fills from 0 to 1 over the second half
			var raw_progress = mount_hold_times[i] / PICKUP_HOLD_DURATION
			var visual_progress = clamp((raw_progress - 0.5) / 0.5, 0.0, 1.0)
			
			var mount_pos = mounts[i].position
			draw_arc(mount_pos, 15.0, -PI/2, -PI/2 + visual_progress * TAU, 32, Color.WHITE, 2.0)

	# --- Debug Overlay (Toggle with F3) ---
	if DebugManager.show_debug:
		# Debug Input Visualization
		var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input_dir.length() > 0:
			draw_line(Vector2.ZERO, input_dir * 50, Color.GREEN, 4.0)

		# Debug Aim Visualization
		var aim_dir = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
		if aim_dir.length() > 0:
			draw_line(Vector2.ZERO, aim_dir * 50, Color.BLUE, 4.0)
		
		# VISUALIZE ACTUAL ROTATION
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(rotation) * 100.0, Color.MAGENTA, 2.0)
		

@export var max_hp: float = 100.0
var current_hp: float = 100.0:
	set(val):
		current_hp = val
		if is_inside_tree():
			_update_health_hud()

@rpc("any_peer", "call_local")
func take_damage(amount: float, attacker_id: int):
	# Friendly Fire Logic
	# "Friendly fire should split the damage between both the Target and the player."
	# If attacker is a teammate (which is everyone in "global game" unless we have teams? 
	# The prompt implies "team-dark" vs others? Or just "global game that all players join".
	# "Friendly fire should split the damage". This implies all players can hurt each other.
	
	if not multiplayer.is_server():
		return # Damage is server-authoritative
		
	var actual_damage = amount
	
	if attacker_id != player_id: # If not self-damage
		# Assume all players are "friendly" for now as it's a co-op style or free-for-all?
		# "The game has drop-in multiplayer... Friendly fire should split"
		# Let's apply the split.
		actual_damage = amount * 0.5
		
		# Also damage the attacker
		# We need to find the attacker player node
		var attacker_node = get_tree().current_scene.find_child(str(attacker_id), true, false)
		if attacker_node and attacker_node.has_method("take_damage_direct"):
			attacker_node.take_damage_direct(amount * 0.5) # Direct damage to avoid recursive splitting
	
	take_damage_direct(actual_damage)

func take_damage_direct(amount: float):
	current_hp -= amount
	print("Player ", player_id, " took ", amount, " damage. HP: ", current_hp)
	# Spawn damage particles (50% chance, handled by ParticleSpawner)
	ParticleSpawner.spawn_damage(global_position)
	# Notify the owning client about HP change
	_sync_hp_to_client.rpc_id(player_id, current_hp)
	if current_hp <= 0:
		die()

func _update_health_hud():
	var is_local = (player_id == multiplayer.get_unique_id())
	if is_local:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("update_health"):
			hud.update_health(current_hp / max_hp)

@export var is_dead: bool = false:
	set(val):
		is_dead = val
		visible = not is_dead
		if has_node("CollisionShape2D"):
			$CollisionShape2D.set_deferred("disabled", is_dead)

func die():
	if is_dead: return
	
	print("Player ", player_id, " died!")
	is_dead = true
	
	# Death explosion particles
	ParticleSpawner.spawn_death(global_position, Color(0.2, 0.8, 1.0))
	
	# Reset HP but stay dead until respawn
	current_hp = 0
	_sync_hp_to_client.rpc_id(player_id, 0)
	
	# Sync death state to everyone
	_sync_death_state.rpc(true)
	
	# Notify GameManager to handle respawn timer (Server only)
	# Notify GameManager to handle respawn timer (Server only)
	if multiplayer.is_server():
		var gm = get_tree().get_first_node_in_group("managers")
		if not gm: gm = get_tree().root.find_child("Game", true, false)
		if not gm: gm = get_tree().root.find_child("GameManager", true, false)
		if not gm: gm = get_tree().root.find_child("TrainingManager", true, false)
		if not gm: gm = get_tree().current_scene
			
		if gm and gm.has_method("on_player_died"):
			gm.on_player_died(player_id)
		else:
			var err = "CRITICAL ERROR: No Manager found (Server)."
			if gm: err = "CRITICAL ERROR: Manager found (" + gm.name + ") but missing on_player_died!"
			print(err)

@rpc("any_peer", "call_local", "reliable")
func respawn(pos: Vector2):
	print("Player ", player_id, " respawning at ", pos)
	position = pos
	current_hp = max_hp
	_sync_hp_to_client.rpc_id(player_id, max_hp)
	
	is_dead = false
	_sync_death_state.rpc(false)

@rpc("call_local", "reliable")
func _sync_death_state(dead: bool):
	is_dead = dead


@rpc("any_peer", "call_local", "reliable")
func _sync_hp_to_client(hp: float):
	current_hp = hp
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_health"):
		hud.update_health(current_hp / max_hp)

func _process(delta):
	# Update label text in case it changed via sync
	if name_label and name_label.text != player_name:
		name_label.text = player_name
		
	if is_multiplayer_authority():
		_check_pointing_at_others(delta)
		_update_nearest_pickup()
		
		if DebugManager.show_debug and Input.is_action_just_pressed("toggle_debug"):
			var p_count = get_tree().get_nodes_in_group("pickups").size()
			print("[DEBUG] Current pickups in world: ", p_count)
			if nearest_pickup:
				print("[DEBUG] Nearest pickup: ", nearest_pickup.pickup_name, " at dist ", global_position.distance_to(nearest_pickup.global_position))
		
	queue_redraw() # Continuous redraw for debug inputs

func _check_pointing_at_others(delta):
	var others = get_tree().get_nodes_in_group("players")
	var my_dir = Vector2.from_angle(rotation)
	
	for other in others:
		if other == self:
			continue
		
		# Calculate angle to other player
		var to_other = (other.global_position - global_position)
		var dist = to_other.length()
		
		var is_pointing = false
		if dist < 800: # Range limit
			var dot = my_dir.dot(to_other.normalized())
			# Dot > 0.95 is roughly within ~18 degrees
			if dot > 0.98:
				is_pointing = true
		
		if is_pointing:
			other.reveal_name(delta, true)
		else:
			# Only fade out if no one is pointing? 
			# Actually since this runs locally on MY screen, 
			# I am the only one who can point at things on my screen.
			other.reveal_name(delta, false)

func reveal_name(delta, show: bool):
	if not name_label: return
	
	var target_alpha = 0.6 if show else 0.0 # "faint name label"
	name_label.modulate.a = lerp(name_label.modulate.a, target_alpha, delta * 5.0)

