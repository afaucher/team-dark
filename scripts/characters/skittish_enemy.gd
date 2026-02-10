extends "res://scripts/characters/bt_enemy.gd"

## SkittishEnemy
## Variant that flees from players and drops unique loot.

func _setup_logic():
	super._setup_logic()
	speed = 350.0 # Fast
	max_hp = 30.0 # Fragile
	color_theme = Color.CYAN
	
	# Drop Data Core logic would go into a modified die() or loot system
	
func die(attacker_id: int):
	# Spawn unique loot
	_spawn_bonus_loot()
	super.die(attacker_id)

func _spawn_bonus_loot():
	# Placeholder for spawning a high-value pickup
	print("[Skittish] Dropping Data Core!")
