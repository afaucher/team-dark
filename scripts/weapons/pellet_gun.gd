extends Node2D

@export var weapon_name: String = "Pellet Gun"
@export var projectile_scene: PackedScene
@export var fire_rate: float = 1.0 # Shots per second (1.0 = 1 shot every 1s)

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
	# Premium Neon Vector Pellet Gun
	var barrel_length = 26.0
	var barrel_width = 10.0
	var color = Color(0.1, 1.2, 1.5, 1.0) # Bright Cyan HDR
	
	# 1. Main Tube
	var points = PackedVector2Array([
		Vector2(0, -barrel_width/2),
		Vector2(barrel_length, -2),
		Vector2(barrel_length, 2),
		Vector2(0, barrel_width/2),
		Vector2(0, -barrel_width/2)
	])
	
	draw_polyline(points, color * Color(1, 1, 1, 0.2), 10.0)
	draw_colored_polygon(points, Color.BLACK)
	draw_polyline(points, color, 2.0)
	
	# 2. Internal Energy Rail
	draw_line(Vector2(2, 0), Vector2(barrel_length - 4, 0), color * 0.4, 4.0)
	draw_line(Vector2(2, 0), Vector2(barrel_length - 4, 0), Color.WHITE, 1.0)
	
	# 3. High-intensity tip
	if can_fire:
		draw_circle(Vector2(barrel_length, 0), 2.5, Color.WHITE)
		draw_circle(Vector2(barrel_length, 0), 4.0, color * 0.3)


func trigger(just_pressed: bool, is_held: bool):
	# Requirement: "require you to pull the trigger each time"
	if just_pressed and can_fire:
		shoot()
		can_fire = false
		_timer.start()
		_update_hud_status()

func get_attacker_id() -> int:
	var parent = get_parent() # Mount
	if parent:
		var grand_parent = parent.get_parent() # Player
		if grand_parent and "player_id" in grand_parent:
			return grand_parent.player_id
	return 1 # Fallback

func shoot():
	if projectile_scene:
		if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
			_request_shoot.rpc_id(1) # Ask server to shoot
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
	
	# Set owner to prevent self-damage
	if "owner_node" in projectile:
		var mount = get_parent()
		if mount:
			projectile.owner_node = mount.get_parent() # Player or Enemy
	
	# Add to the current scene "Projectiles" node
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
				if hud and hud.has_method("update_weapon_status"):
					hud.update_weapon_status(idx, can_fire, 1.0)
