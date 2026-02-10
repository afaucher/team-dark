extends "res://scripts/weapons/weapon.gd"

## Missile Launcher
## Inherits from base weapon, specializes in firing tracking missiles.

func _ready():
	super._ready()
	# Set default missile stats
	fire_rate = 1.5
	damage = 25.0
	projectile_speed = 400.0 # Starts slow, accelerates
	if not projectile_scene:
		projectile_scene = load("res://scenes/projectiles/missile.tscn")

func _draw():
	# Premium Neon Vector Missile Pod
	var pod_size = 24.0
	var color = Color(0.2, 1.0, 0.2, 1.0) # Lime Green HDR
	
	# pod background
	var rect = Rect2(0, -pod_size/2, pod_size, pod_size)
	draw_polyline([
		Vector2(0, -pod_size/2), Vector2(pod_size, -pod_size/2), 
		Vector2(pod_size, pod_size/2), Vector2(0, pod_size/2),
		Vector2(0, -pod_size/2)
	], color * Color(1, 1, 1, 0.2), 14.0)
	
	draw_colored_polygon([
		Vector2(0, -pod_size/2), Vector2(pod_size, -pod_size/2), 
		Vector2(pod_size, pod_size/2), Vector2(0, pod_size/2)
	], Color.BLACK)
	
	draw_rect(rect, color, false, 2.5)
	
	# 4 Missile Tubes
	var tube_r = 4.0
	var tube_offsets = [Vector2(6, -6), Vector2(18, -6), Vector2(6, 6), Vector2(18, 6)]
	for offset in tube_offsets:
		draw_circle(offset, tube_r, Color.BLACK)
		draw_arc(offset, tube_r, 0, TAU, 12, color, 1.5)
		if can_fire:
			draw_circle(offset, 1.5, Color.WHITE)
		else:
			draw_circle(offset, 1.5, color * 0.2)
