extends Node2D

@export var weapon_name: String = "Grenade Launcher"
@export var projectile_scene: PackedScene
@export var fire_rate: float = 0.5 # 2 seconds between shots

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
	# Premium Neon Vector Grenade Launcher
	var barrel_length = 28.0
	var barrel_width = 16.0
	var drum_radius = 10.0
	var color = Color(1.0, 0.3, 0.4, 1.0) # Pinkish Red HDR
	
	# 1. Drum Magazine (under barrel)
	draw_circle(Vector2(6, 4), drum_radius, Color.BLACK)
	draw_arc(Vector2(6, 4), drum_radius, 0, TAU, 16, color, 2.0)
	# Drum details
	for i in range(6):
		var angle = i * TAU / 6
		draw_circle(Vector2(6, 4) + Vector2.from_angle(angle) * 6, 2, color * 0.5)
	
	# 2. Heavy Barrel
	var barrel_points = PackedVector2Array([
		Vector2(0, -barrel_width/2),
		Vector2(barrel_length, -barrel_width/2),
		Vector2(barrel_length, barrel_width/2),
		Vector2(0, barrel_width/2),
		Vector2(0, -barrel_width/2)
	])
	
	draw_polyline(barrel_points, color * Color(1, 1, 1, 0.2), 10.0)
	draw_colored_polygon(barrel_points, Color.BLACK)
	draw_polyline(barrel_points, color, 3.0)
	
	# Barrel detailing (Vent holes)
	for i in range(3):
		draw_rect(Rect2(8 + i*6, -3, 3, 6), color * 0.4, true)
	
	# 3. Muzzle / Ready indicator
	if can_fire:
		draw_rect(Rect2(barrel_length - 2, -barrel_width/2 - 2, 4, barrel_width + 4), Color.WHITE)
		draw_rect(Rect2(barrel_length - 2, -barrel_width/2 - 2, 4, barrel_width + 4), color, false, 1.0)

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
			_spawn_projectile()

@rpc("any_peer", "call_local")
func _request_shoot():
	_spawn_projectile()

func _spawn_projectile():
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.global_rotation = global_rotation
	
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
