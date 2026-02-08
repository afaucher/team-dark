class_name Enemy
extends CharacterBody2D

@export var max_hp: float = 100.0
@export var speed: float = 150.0
@export var color_theme: Color = Color("#ff9a00")
@export var attack_range: float = 200.0

var current_hp: float

func _ready():
	current_hp = max_hp
	# Set visual color if a sprite/renderer exists (setup in _draw or scene)
	queue_redraw()

func _physics_process(delta):
	if multiplayer.is_server():
		var target = _get_nearest_player()
		if target:
			var dir = (target.global_position - global_position).normalized()
			velocity = dir * speed
			rotation = dir.angle()
			
			# Attack logic here
			if global_position.distance_to(target.global_position) < attack_range:
				_attack(target)
		else:
			velocity = Vector2.ZERO
		
		move_and_slide()

func _get_nearest_player():
	var nearest = null
	var min_dist = INF
	# Assuming players are in a group "players"
	for player in get_tree().get_nodes_in_group("players"):
		var dist = global_position.distance_to(player.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = player
	return nearest

func take_damage(amount: float, attacker_id: int):
	current_hp -= amount
	if current_hp <= 0:
		die()

func die():
	print("Enemy died")
	queue_free()

func _attack(target):
	# Placeholder for attack logic (e.g., fire weapon)
	pass

func _draw():
	# Neon Vector Style
	var radius = 20.0
	
	# Draw different shapes based on color/tier to make them distinct
	# (Heuristic: Orange=Triangle, Purple=Square, Green=Hex/Circle)
	
	if color_theme.to_html().begins_with("ff9a"): # Orange (Triangle)
		var points = PackedVector2Array([
			Vector2(radius, 0).rotated(0),
			Vector2(radius, 0).rotated(2.094), # 120 deg
			Vector2(radius, 0).rotated(4.188), # 240 deg
			Vector2(radius, 0).rotated(0)
		])
		draw_colored_polygon(points, Color.BLACK) # Fill
		draw_polyline(points, color_theme, 3.0)   # Glow Outline
		
	elif color_theme.to_html().begins_with("b829"): # Purple (Square)
		var r = radius * 0.8
		var points = PackedVector2Array([
			Vector2(-r, -r), Vector2(r, -r),
			Vector2(r, r), Vector2(-r, r),
			Vector2(-r, -r)
		])
		draw_colored_polygon(points, Color.BLACK)
		draw_polyline(points, color_theme, 3.0)
		
	else: # Green/Default (Circle)
		draw_circle(Vector2.ZERO, radius - 2, Color.BLACK)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color_theme, 3.0, true)

	# Orientation indicator (Line)
	draw_line(Vector2.ZERO, Vector2(radius + 10, 0), color_theme, 2.0)
	
	# Weapon Mount Indicator (Simulated front mount)
	var mount_pos = Vector2(radius, 0) # Front center
	draw_circle(mount_pos, 5.0, Color.BLACK)
	draw_circle(mount_pos, 3.0, Color.RED)
