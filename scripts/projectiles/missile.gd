extends Projectile

## Missile Projectile
## Features steering logic to track the target.

@export var steer_force: float = 50.0
@export var max_speed: float = 1200.0
@export var acceleration: float = 400.0

var target: Node2D = null
var current_velocity: Vector2

func _ready():
	super._ready()
	current_velocity = velocity
	# Find nearest player as initial target
	target = _find_nearest_player()

func _physics_process(delta):
	if target and is_instance_valid(target):
		var desired = (target.global_position - global_position).normalized() * max_speed
		var steer = (desired - current_velocity).normalized() * steer_force
		current_velocity += steer * delta
	else:
		# Search for target if lost
		target = _find_nearest_player()
		
	current_velocity = current_velocity.normalized() * (current_velocity.length() + acceleration * delta)
	current_velocity = current_velocity.limit_length(max_speed)
	
	position += current_velocity * delta
	rotation = current_velocity.angle()

func _find_nearest_player():
	var players = get_tree().get_nodes_in_group("players")
	var nearest = null
	var min_d = 2000.0
	for p in players:
		var d = global_position.distance_to(p.global_position)
		if d < min_d:
			min_d = d
			nearest = p
	return nearest
