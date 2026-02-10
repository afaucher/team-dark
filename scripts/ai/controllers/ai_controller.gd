extends Node

# Input buffers that the character will read
var move_vector: Vector2 = Vector2.ZERO
var aim_vector: Vector2 = Vector2.ZERO
var fire_just_pressed: Array[bool] = [false, false, false] # Left, Right, Front
var fire_held: Array[bool] = [false, false, false]
var fire_all_just: bool = false
var fire_all_held: bool = false

var character: CharacterBody2D

func _ready():
	character = get_parent()
	if not character is CharacterBody2D:
		push_error("AIController must be a child of a CharacterBody2D")

func update_actions(_delta: float):
	# Override in subclasses
	pass

func reset_inputs():
	move_vector = Vector2.ZERO
	# Aim vector is usually persistent
	for i in range(3):
		fire_just_pressed[i] = false
		fire_held[i] = false
	fire_all_just = false
	fire_all_held = false
