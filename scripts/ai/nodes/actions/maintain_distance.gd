extends "res://addons/beehave/nodes/leaves/action.gd"

## MaintainDistance Action
## Keeps the actor at a specific range from the nearest player.

@export var ideal_distance: float = 600.0
@export var tolerance: float = 50.0

func tick(actor: Node, blackboard: Blackboard) -> int:
	var target = blackboard.get_value("nearest_player")
	if not target or not is_instance_valid(target):
		return FAILURE
		
	var to_target = target.global_position - actor.global_position
	var dist = to_target.length()
	
	var dir = to_target.normalized()
	var move_dir = Vector2.ZERO
	
	if dist > ideal_distance + tolerance:
		# Too far, move closer
		move_dir = dir
	elif dist < ideal_distance - tolerance:
		# Too close, move away
		move_dir = -dir
	else:
		# Good distance, maybe strafe or stop
		move_dir = Vector2.ZERO
		
	if "velocity" in actor and "speed" in actor:
		actor.velocity = move_dir * actor.speed
		actor.rotation = lerp_angle(actor.rotation, dir.angle(), 0.1)
		
	return RUNNING
