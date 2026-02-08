extends Control

enum WeaponType { NONE, PELLET_GUN }

var type: WeaponType = WeaponType.NONE:
	set(val):
		type = val
		queue_redraw()

func _draw():
	match type:
		WeaponType.PELLET_GUN:
			_draw_pellet_gun()

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
	# Tip
	draw_circle(Vector2(barrel_length/2, 0), 3.0, Color.WHITE)
