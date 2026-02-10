extends "res://scripts/characters/bt_enemy.gd"

## MortarEnemy
## Variant that maintains distance and fires heavy shots.

func _setup_logic():
	super._setup_logic()
	speed = 120.0 # Slow
	max_hp = 120.0 # Beefy
	color_theme = Color.ORANGE
	
	# Equip a heavy weapon (Placeholder path)
	equip_weapon(2, "res://scenes/weapons/machine_gun.tscn")
