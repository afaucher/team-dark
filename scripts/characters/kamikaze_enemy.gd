extends "res://scripts/characters/bt_enemy.gd"

## KamikazeEnemy
## Variant that rushes the player and explodes.

@export var explosion_damage: float = 60.0
@export var explosion_radius: float = 150.0

func _setup_logic():
	super._setup_logic()
	max_hp = 25.0
	speed = 400.0
	color_theme = ThemeManager.enemy_kamikaze
	shape_type = "circle"
func _physics_process(delta):
	super._physics_process(delta)

func detonate():
	# AOE Damage
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		var d = global_position.distance_to(p.global_position)
		if d < explosion_radius:
			var falloff = 1.0 - (d / explosion_radius)
			if p.has_method("take_damage"):
				p.take_damage(explosion_damage * falloff, -1)
				
	# Self destruct
	die(-1)
