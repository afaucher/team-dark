extends "res://scripts/characters/bt_enemy.gd"

func _setup_logic():
	super._setup_logic()
	max_hp = 40.0
	speed = 150.0
	color_theme = Color.GRAY
	shape_type = "circle"
