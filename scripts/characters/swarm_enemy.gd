extends "res://scripts/characters/bt_enemy.gd"

func _setup_logic():
	super._setup_logic()
	max_hp = 20.0
	speed = 280.0
	color_theme = Color.LIME_GREEN
	shape_type = "hex"
	
	if is_multiplayer_authority():
		add_to_group("swarm")
