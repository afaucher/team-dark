class_name Enemy
extends CharacterBody2D

@export var max_hp: float = 100.0
@export var speed: float = 150.0
@export var color_theme: Color = Color.GRAY
@export var attack_range: float = 200.0

var current_hp: float

func _ready():
	current_hp = max_hp
	# Set visual color if a sprite/renderer exists (setup in _draw or scene)
	queue_redraw()

func _physics_process(delta):
	if multiplayer.is_server():
		var target = _get_nearest_player()
		if target:
			var dir = (target.global_position - global_position).normalized()
			velocity = dir * speed
			rotation = dir.angle()
			
			# Attack logic here
			if global_position.distance_to(target.global_position) < attack_range:
				_attack(target)
		else:
			velocity = Vector2.ZERO
		
		move_and_slide()

func _get_nearest_player():
	var nearest = null
	var min_dist = INF
	# Assuming players are in a group "players"
	for player in get_tree().get_nodes_in_group("players"):
		var dist = global_position.distance_to(player.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = player
	return nearest

func take_damage(amount: float, attacker_id: int):
	current_hp -= amount
	if current_hp <= 0:
		die()

func die():
	print("Enemy died")
	queue_free()

func _attack(target):
	# Placeholder for attack logic (e.g., fire weapon)
	pass

func _draw():
	# Simple vector art representation if no sprite
	draw_circle(Vector2.ZERO, 16, color_theme)
	draw_circle(Vector2.ZERO, 14, Color.BLACK) # Hollow effect
	# Orientation indicator
	draw_line(Vector2.ZERO, Vector2(20, 0), color_theme, 2.0)
