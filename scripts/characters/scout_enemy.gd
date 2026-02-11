extends "res://scripts/characters/bt_enemy.gd"

func _setup_logic():
	super._setup_logic()
	max_hp = 30.0
	speed = 300.0
	tier = 2
	shape_type = "triangle"
