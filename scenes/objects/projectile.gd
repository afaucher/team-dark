class_name Projectile
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 0.0
var owner_id: int = 0
var lifetime: float = 2.0

func setup(pos: Vector2, dir: Vector2, speed: float, dmg: float, _owner_id: int):
	position = pos
	velocity = dir * speed
	damage = dmg
	owner_id = _owner_id
	rotation = dir.angle()

func _ready():
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta):
	position += velocity * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		# Check logic for friendly fire or self-damage
		# Friendly fire splits damage:
		# "Friendly fire should split the damage between both the Target and the player."
		var is_friendly = false 
		# TODO: Check team/user logic
		
		body.take_damage(damage, owner_id)
	
	# Destroy on wall hit (layer check usually handled by collision mask)
	queue_free()
