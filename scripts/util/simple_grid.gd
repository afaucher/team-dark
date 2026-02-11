extends Node2D

func _draw():
	var size = 4000
	var step = 120
	var color = ThemeManager.grid_main # Violet @ 20%
	
	for x in range(-size, size + step, step):
		draw_line(Vector2(x, -size), Vector2(x, size), color, 1.0)
	
	for y in range(-size, size + step, step):
		draw_line(Vector2(-size, y), Vector2(size, y), color, 1.0)
