extends Node2D

@export var weapon_name: String = "Machine Gun"
@export var projectile_scene: PackedScene
@export var fire_rate: float = 10.0 # Fast!

var can_fire: bool = true
var _timer: Timer

@export var max_ammo: float = 50.0
var current_ammo: float = 50.0
var is_reloading: bool = false
var _reload_timer: Timer

func _ready():
	_timer = Timer.new()
	_timer.wait_time = 1.0 / fire_rate
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	
	_reload_timer = Timer.new()
	_reload_timer.wait_time = 10.0
	_reload_timer.one_shot = true
	_reload_timer.timeout.connect(_on_reload_complete)
	add_child(_reload_timer)
	
	queue_redraw()
	_update_hud_status("READY")

func _draw():
	# Premium Neon Vector Machine Gun
	var barrel_length = 30.0
	var barrel_width = 12.0
	var color = Color(1.3, 0.7, 0.1, 1.0) # Amber HDR
	
	# 1. Cooling Shroud (Background)
	var shroud_points = PackedVector2Array([
		Vector2(0, -barrel_width/2),
		Vector2(barrel_length-6, -barrel_width/2),
		Vector2(barrel_length, -2),
		Vector2(barrel_length, 2),
		Vector2(barrel_length-6, barrel_width/2),
		Vector2(0, barrel_width/2),
		Vector2(0, -barrel_width/2)
	])
	
	draw_polyline(shroud_points, color * Color(1, 1, 1, 0.2), 12.0)
	draw_colored_polygon(shroud_points, Color.BLACK)
	draw_polyline(shroud_points, color, 2.5)
	
	# 2. Dual Barrels (Inside Shroud)
	draw_line(Vector2(2, -3), Vector2(barrel_length-2, -3), color, 2.0)
	draw_line(Vector2(2, 3), Vector2(barrel_length-2, 3), color, 2.0)
	
	# 3. Ammo Status
	if not is_reloading:
		var ammo_ratio = current_ammo / max_ammo
		# Segmented ammo display
		for i in range(10):
			var segment_color = color if (float(i)/10.0 < ammo_ratio) else color * 0.2
			draw_rect(Rect2(4 + i*2.2, -barrel_width/2 + 2, 1.5, 2), segment_color, true)
	else:
		# Reloading pulse
		var p = (sin(Time.get_ticks_msec() * 0.01) + 1.0) * 0.5
		draw_rect(Rect2(4, -barrel_width/2 + 2, barrel_length-8, 2), color * Color(1, 0.2, 0.2, p * 0.5), true)

func trigger(just_pressed: bool, is_held: bool):
	if is_reloading:
		return
		
	# Machine Gun allows holding the trigger
	if is_held and can_fire and current_ammo > 0:
		shoot()
		current_ammo -= 1.0
		can_fire = false
		_timer.start()
		_update_hud_status("READY")
		
		if current_ammo <= 0:
			start_reload()

func _update_hud_status(status: String = ""):
	var parent = get_parent() # Mount
	if parent:
		var player = parent.get_parent() # Player
		if player and player.is_multiplayer_authority():
			var idx = -1
			if "mounts" in player:
				for i in range(player.mounts.size()):
					if player.mounts[i] == parent:
						idx = i
						break
			if idx != -1:
				var hud = get_tree().root.find_child("HUD", true, false)
				if hud:
					if status != "":
						hud.update_mount(idx, weapon_name, status)
					
					if hud.has_method("update_weapon_status"):
						var ratio = current_ammo / max_ammo
						hud.update_weapon_status(idx, not is_reloading, ratio)

func start_reload():
	is_reloading = true
	_reload_timer.start()
	_update_hud_status("RELOADING...")

func _on_reload_complete():
	current_ammo = max_ammo
	is_reloading = false
	can_fire = true
	_update_hud_status("READY")
	queue_redraw()

func _process(_delta):
	# Continuous redraw for ammo bar animation if needed, but mostly on shots
	pass

func get_attacker_id() -> int:
	var parent = get_parent()
	if parent:
		var grand_parent = parent.get_parent()
		if grand_parent and "player_id" in grand_parent:
			return grand_parent.player_id
	return 1

func shoot():
	if projectile_scene:
		if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
			_request_shoot.rpc_id(1)
		else:
			_spawn_projectile()

@rpc("any_peer", "call_local")
func _request_shoot():
	_spawn_projectile()

func _spawn_projectile():
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.global_rotation = global_rotation
	
	# Add slight spread
	projectile.global_rotation += randf_range(-0.1, 0.1)
	
	if "attacker_id" in projectile:
		projectile.attacker_id = get_attacker_id()
	
	# Set owner to prevent self-damage
	if "owner_node" in projectile:
		var mount = get_parent()
		if mount:
			projectile.owner_node = mount.get_parent() # Player or Enemy
	
	var projectiles_node = get_tree().root.find_child("Projectiles", true, false)
	if projectiles_node:
		projectiles_node.add_child(projectile, true)
	else:
		get_tree().current_scene.add_child(projectile)

func _on_timer_timeout():
	can_fire = true
	queue_redraw()
