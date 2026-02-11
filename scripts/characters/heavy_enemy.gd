extends "res://scripts/characters/bt_enemy.gd"

func _setup_logic():
	super._setup_logic()
	max_hp = 150.0
	speed = 100.0
	tier = 3
	shape_type = "square"
