extends "res://scripts/weapons/weapon.gd"

## Laser Rifle
## Fires a continuous or pulsed hitscan beam.

@export var beam_duration: float = 0.5
@export var warning_duration: float = 0.3 # Time before beam deals damage

func fire():
	if not can_fire: return
	can_fire = false
	fire_timer.start()
	
	# Visual only on server for now, or use RPC
	if multiplayer.is_server():
		_perform_hitscan()

func _perform_hitscan():
	var space_state = get_world_2d().direct_space_state
	var dir = Vector2.RIGHT.rotated(global_rotation)
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + dir * 2000.0)
	query.collision_mask = 1 | 4 # Walls, Enemies, Players (adjust as needed)
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		if collider.has_method("take_damage"):
			var owner_id = 0 # Default
			if get_parent().get_parent().has_method("get_player_id"):
				owner_id = get_parent().get_parent().player_id
				
			collider.take_damage(damage, owner_id)

func _draw():
	# Premium Neon Vector Laser Rifle
	var barrel_length = 32.0
	var ColorBlue = Color(0.2, 0.4, 2.0, 1.0) # Electric Blue HDR
	
	# 1. Sleek Rail Body
	var body_points = PackedVector2Array([
		Vector2(0, -4),
		Vector2(barrel_length, -2),
		Vector2(barrel_length, 2),
		Vector2(0, 4),
		Vector2(0, -4)
	])
	
	draw_polyline(body_points, ColorBlue * Color(1, 1, 1, 0.3), 8.0)
	draw_colored_polygon(body_points, Color.BLACK)
	draw_polyline(body_points, ColorBlue, 1.5)
	
	# 2. Power Rails
	draw_line(Vector2(4, -5), Vector2(barrel_length-4, -5), ColorBlue * 0.5, 1.0)
	draw_line(Vector2(4, 5), Vector2(barrel_length-4, 5), ColorBlue * 0.5, 1.0)
	
	# 3. Core Battery (Hex)
	var hex_points = PackedVector2Array()
	for i in range(6):
		hex_points.append(Vector2(6, 0) + Vector2.from_angle(i * TAU / 6) * 6)
	draw_colored_polygon(hex_points, Color.BLACK)
	draw_polyline(hex_points, ColorBlue, 2.0)
	
	if can_fire:
		# Pulsing core
		var p = (sin(Time.get_ticks_msec() * 0.01) + 1.0) * 0.5
		draw_circle(Vector2(6, 0), 3.0 * p, Color.WHITE)
		draw_circle(Vector2(barrel_length, 0), 2.0, Color.WHITE)
