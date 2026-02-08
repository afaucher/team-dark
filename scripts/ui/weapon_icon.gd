extends Control

enum WeaponType { NONE, PELLET_GUN, MACHINE_GUN, HEALTH_KIT }

var type: WeaponType = WeaponType.NONE:
	set(val):
		type = val
		queue_redraw()

var is_ready: bool = true:
	set(val):
		is_ready = val
		queue_redraw()

var ammo_ratio: float = 1.0:
	set(val):
		ammo_ratio = clamp(val, 0.0, 1.0)
		queue_redraw()

func _draw():
	match type:
		WeaponType.PELLET_GUN:
			_draw_pellet_gun()
		WeaponType.MACHINE_GUN:
			_draw_machine_gun()
		WeaponType.HEALTH_KIT:
			_draw_health_kit()

func _draw_pellet_gun():
	var color = Color(0.0, 2.0, 2.0, 1.0) # Cyan HDR
	var barrel_length = 30.0
	var barrel_width = 12.0
	
	# Horizontal icon
	var rect = Rect2(-barrel_length/2, -barrel_width/2, barrel_length, barrel_width)
	
	# Glow
	draw_rect(rect, color * Color(1, 1, 1, 0.3), false, 4.0)
	# Body
	draw_rect(rect, Color.BLACK, true)
	# Outline
	draw_rect(rect, color, false, 2.0)
	# Tip (Only if ready)
	if is_ready:
		draw_circle(Vector2(barrel_length/2, 0), 3.0, Color.WHITE)

func _draw_machine_gun():
	var color = Color(1.0, 0.5, 0.0, 1.0) # Orange
	var barrel_length = 35.0
	var barrel_width = 15.0
	var rect = Rect2(-barrel_length/2, -barrel_width/2, barrel_length, barrel_width)
	draw_rect(rect, color * Color(1, 1, 1, 0.3), false, 4.0)
	draw_rect(rect, Color.BLACK, true)
	draw_rect(rect, color, false, 2.0)
	# Muzzle
	draw_rect(Rect2(barrel_length/2-6, -barrel_width/2-2, 6, barrel_width+4), color, false, 2.0)
	
	# Ammo Bar
	if ammo_ratio > 0:
		var bar_padding = 4.0
		var bar_rect = Rect2(-barrel_length/2 + bar_padding, -barrel_width/2 + bar_padding, (barrel_length - bar_padding*2) * ammo_ratio, barrel_width - bar_padding*2)
		draw_rect(bar_rect, Color.WHITE, true)

func _draw_health_kit():
	var color = Color(1.0, 0.0, 0.0, 1.0) # Red
	var size = 20.0
	var rect = Rect2(-size/2, -size/2, size, size)
	draw_rect(rect, color * Color(1, 1, 1, 0.3), false, 4.0)
	draw_rect(rect, Color.BLACK, true)
	draw_rect(rect, color, false, 2.0)
	# Plus
	draw_line(Vector2(-5, 0), Vector2(5, 0), Color.WHITE, 2.0)
	draw_line(Vector2(0, -5), Vector2(0, 5), Color.WHITE, 2.0)
