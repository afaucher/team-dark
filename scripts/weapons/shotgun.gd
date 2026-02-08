extends Node2D

@export var weapon_name: String = "Shotgun"
@export var projectile_scene: PackedScene
@export var fire_rate: float = 1.0 # Shots per second
@export var pellet_count: int = 8
@export var spread_degrees: float = 25.0

var can_fire: bool = true
var _timer: Timer

func _ready():
	_timer = Timer.new()
	_timer.wait_time = 1.0 / fire_rate
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	queue_redraw()
	_update_hud_status()

func _draw():
	# Vector Style Shotgun
	var barrel_length = 22.0
	var barrel_width = 12.0
	var color = Color(1.0, 0.5, 0.0, 1.0) # Orange HDR
	
	var points = PackedVector2Array([
		Vector2(0, -barrel_width/2),
		Vector2(barrel_length, -barrel_width/2),
		Vector2(barrel_length, barrel_width/2),
		Vector2(0, barrel_width/2),
		Vector2(0, -barrel_width/2)
	])
	
	draw_polyline(points, color * Color(1, 1, 1, 0.3), 6.0)
	draw_colored_polygon(points, Color.BLACK)
	draw_polyline(points, color, 2.5)
	
	if can_fire:
		draw_circle(Vector2(barrel_length, 2), 2.0, Color.WHITE)
		draw_circle(Vector2(barrel_length, -2), 2.0, Color.WHITE)

func trigger(just_pressed: bool, is_held: bool):
	if just_pressed and can_fire:
		shoot()
		can_fire = false
		_timer.start()
		_update_hud_status()

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
			_spawn_projectiles()

@rpc("any_peer", "call_local")
func _request_shoot():
	_spawn_projectiles()

func _spawn_projectiles():
	for i in range(pellet_count):
		var projectile = projectile_scene.instantiate()
		projectile.global_position = global_position
		
		# Apply spread
		var angle_offset = deg_to_rad(randf_range(-spread_degrees, spread_degrees))
		projectile.global_rotation = global_rotation + angle_offset
		
		if "attacker_id" in projectile:
			projectile.attacker_id = get_attacker_id()
		
		if "owner_node" in projectile:
			var mount = get_parent()
			if mount:
				projectile.owner_node = mount.get_parent()
		
		var projectiles_node = get_tree().root.find_child("Projectiles", true, false)
		if projectiles_node:
			projectiles_node.add_child(projectile, true)
		else:
			get_tree().current_scene.add_child(projectile)

func _on_timer_timeout():
	can_fire = true
	_update_hud_status()
	queue_redraw()

func _update_hud_status():
	var parent = get_parent()
	if parent:
		var player = parent.get_parent()
		if player and player.is_multiplayer_authority():
			var idx = -1
			if "mounts" in player:
				for i in range(player.mounts.size()):
					if player.mounts[i] == parent:
						idx = i
						break
			if idx != -1:
				var hud = get_tree().root.find_child("HUD", true, false)
				if hud and hud.has_method("update_weapon_status"):
					hud.update_weapon_status(idx, can_fire, 1.0)
