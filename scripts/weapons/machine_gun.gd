extends Node2D

@export var weapon_name: String = "Machine Gun"
@export var projectile_scene: PackedScene
@export var fire_rate: float = 10.0 # Fast!

var can_fire: bool = true
var _timer: Timer

func _ready():
	_timer = Timer.new()
	_timer.wait_time = 1.0 / fire_rate
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	queue_redraw()

func _draw():
	# Neon Vector Machine Gun Style
	var barrel_length = 25.0
	var barrel_width = 10.0
	var color = Color(1.0, 0.5, 0.0, 1.0) # Orange HDR
	
	var points = PackedVector2Array([
		Vector2(0, -barrel_width/2),
		Vector2(barrel_length, -barrel_width/2),
		Vector2(barrel_length, barrel_width/2),
		Vector2(0, barrel_width/2),
		Vector2(0, -barrel_width/2)
	])
	
	draw_polyline(points, color * Color(1, 1, 1, 0.3), 8.0)
	draw_colored_polygon(points, Color.BLACK)
	draw_polyline(points, color, 3.0)
	# Muzzle
	draw_rect(Rect2(barrel_length-4, -barrel_width/2-2, 6, barrel_width+4), color, false, 2.0)

func trigger(just_pressed: bool, is_held: bool):
	# Machine Gun allows holding the trigger
	if is_held and can_fire:
		shoot()
		can_fire = false
		_timer.start()

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
	
	var projectiles_node = get_tree().root.find_child("Projectiles", true, false)
	if projectiles_node:
		projectiles_node.add_child(projectile, true)
	else:
		get_tree().current_scene.add_child(projectile)

func _on_timer_timeout():
	can_fire = true
