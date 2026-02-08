extends CharacterBody2D

const DuckNameGenerator = preload("res://scripts/duck_names.gd")

const SPEED = 600.0
const ACCEL = 2500.0
const FRICTION = 2000.0

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
@onready var name_label = get_node_or_null("NameLabel")

# Pickup System
const PICKUP_HOLD_DURATION = 0.5
const PICKUP_RANGE = 100.0
var mount_hold_times = [0.0, 0.0, 0.0] # Left, Right, Front
var current_mount_weapons = [null, null, null] # PackedScenes for dropping
var nearest_pickup = null

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
	pickup.pickup_name = temp.weapon_name if "weapon_name" in temp else "Weapon"
	temp.free()
	
	pickup.global_position = global_position + Vector2.from_angle(randf() * TAU) * 50.0
	get_tree().current_scene.add_child(pickup, true)
	
	# Clear the mount
	equip_weapon.rpc(mount_index, "")

func heal(amount: float):
	current_hp = min(current_hp + amount, max_hp)
	print("Player ", player_id, " healed by ", amount, ". HP: ", current_hp)

func add_ammo(amount: int):
	print("Player ", player_id, " received ", amount, " ammo.")
	# TODO: Implement ammo system in weapons

func _physics_process(delta):
	if is_multiplayer_authority():
		_handle_input(delta)
	
	move_and_slide()

func _handle_input(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		velocity = velocity.move_toward(direction * SPEED, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	# Aiming (for mounts/visuals)
	# Use raw_aim from _physics_process if possible, but Input here works too
	var aim_dir = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim_dir.length() > 0.1:
		rotation = aim_dir.angle()
		# print("Rotation set to: ", rotation)
	
	# Firing - Check both Just Pressed (for semi-auto) and Pressed (for auto/charging)
	# Left Mount (0)
	var fire_left_just = Input.is_action_just_pressed("fire_left")
	var fire_left_held = Input.is_action_pressed("fire_left")
	if fire_left_just or fire_left_held:
		_fire_mount(0, fire_left_just, fire_left_held)
		
	# Right Mount (1)
	var fire_right_just = Input.is_action_just_pressed("fire_right")
	var fire_right_held = Input.is_action_pressed("fire_right")
	if fire_right_just or fire_right_held:
		_fire_mount(1, fire_right_just, fire_right_held)
		
	# Front Mount (2)
	var fire_front_just = Input.is_action_just_pressed("fire_front")
	var fire_front_held = Input.is_action_pressed("fire_front")
	if fire_front_just or fire_front_held:
		_fire_mount(2, fire_front_just, fire_front_held)
		
	# Fire All (Right Trigger)
	var fire_all_just = Input.is_action_just_pressed("fire_all")
	var fire_all_held = Input.is_action_pressed("fire_all")
	if fire_all_just or fire_all_held:
		for i in range(3):
			_fire_mount(i, fire_all_just, fire_all_held)

	# Update Pickup Hold timers
	_handle_pickup_timers(delta)

func _handle_pickup_timers(delta):
	# Map actions to indices
	var actions = ["fire_left", "fire_right", "fire_front"]
	
	for i in range(3):
		if Input.is_action_pressed(actions[i]):
			mount_hold_times[i] += delta
			if mount_hold_times[i] >= PICKUP_HOLD_DURATION:
				if nearest_pickup:
					_request_pickup(nearest_pickup.get_path(), i)
					mount_hold_times[i] = -1.0 # Prevent multiple triggers
		else:
			mount_hold_times[i] = 0.0

func _request_pickup(pickup_path: NodePath, mount_index: int):
	# Request server to perform pickup
	_srv_pickup.rpc_id(1, pickup_path, mount_index)

@rpc("any_peer", "call_local")
func _srv_pickup(pickup_path: NodePath, mount_index: int):
	if not multiplayer.is_server(): return
	
	var pickup = get_node_or_null(pickup_path)
	if pickup and pickup.has_method("pickup_collected"):
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
	# DEBUG: Log EVERYTHING to help identify trigger indices
	if event is InputEventKey and event.pressed:
		print("P", player_id, " KEY: ", event.as_text())
	elif event is InputEventMouseButton and event.pressed:
		print("P", player_id, " MOUSE: ", event.button_index)
	elif event is InputEventJoypadButton:
		print("P", player_id, " JOY_BUTTON: ", event.button_index, " pressed: ", event.pressed)
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.1: # Much lower threshold for detection
			print("P", player_id, " JOY_AXIS: ", event.axis, " value: ", event.axis_value)
			
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
			if nearest_pickup:
				draw_line(mount_pos, to_local(nearest_pickup.global_position), Color(1,1,1,0.5 * visual_progress), 1.0)

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
		
		# Authority Debug
		var auth_color = Color.GREEN if is_multiplayer_authority() else Color.RED
		draw_circle(Vector2(0, -40), 5.0, auth_color)
		
		# Projectile Tracing
		var projectiles = get_tree().get_nodes_in_group("projectiles")
		for proj in projectiles:
			var rel_pos = to_local(proj.global_position)
			var dist = rel_pos.length()
			
			draw_line(Vector2.ZERO, rel_pos, Color(1, 1, 0, 0.8), 2.0) 
			
			if dist > 500:
				var arrow_pos = rel_pos.limit_length(200)
				draw_circle(arrow_pos, 10.0, Color.RED)
				draw_line(Vector2.ZERO, arrow_pos, Color.RED, 4.0)
			
			draw_circle(rel_pos, 8.0, Color.YELLOW)

@export var max_hp: float = 100.0
var current_hp: float = 100.0

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
	if current_hp <= 0:
		die()

func die():
	print("Player ", player_id, " died!")
	# Respawn logic or game over?
	# "The spawn is always near the player and only after the player is out of combat." (Refers to spawning IN?)
	# For death, maybe just respawn at a safe point.
	current_hp = max_hp
	position = Vector2(100, 100) # Reset position for now

func _process(delta):
	# Update label text in case it changed via sync
	if name_label and name_label.text != player_name:
		name_label.text = player_name
		
	if is_multiplayer_authority():
		_check_pointing_at_others(delta)
		_update_nearest_pickup()
		
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

