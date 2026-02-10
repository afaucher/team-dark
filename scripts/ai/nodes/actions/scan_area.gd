extends "res://addons/beehave/nodes/leaves/action.gd"

## ScanArea Action
## Rotates the actor to "look around" while stationary.

@export var scan_speed: float = 2.0
@export var scan_duration: float = 2.0

var timer: float = 0.0

func tick(actor: Node, blackboard: Blackboard) -> int:
	if timer >= scan_duration:
		timer = 0.0
		return SUCCESS
		
	timer += get_physics_process_delta_time()
	
	# Alternate rotation direction
	var rot_dir = 1 if int(timer * 2.0) % 2 == 0 else -1
	actor.rotation += rot_dir * scan_speed * get_physics_process_delta_time()
	
	if "velocity" in actor:
		actor.velocity = Vector2.ZERO
		
	return RUNNING
