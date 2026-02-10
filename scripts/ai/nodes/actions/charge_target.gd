extends "res://addons/beehave/nodes/leaves/action.gd"

## ChargeTarget Action
## Rushes towards the nearest player at high speed.

@export var charge_speed_mult: float = 2.0
@export var stop_distance: float = 10.0

func tick(actor: Node, blackboard: Blackboard) -> int:
	var target = null
	var min_dist = 2000.0 # Wide detection for charging
	
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		var d = actor.global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			target = p
			
	if not target:
		return FAILURE
		
	var to_target = target.global_position - actor.global_position
	var dist = to_target.length()
	
	if dist < stop_distance:
		return SUCCESS
		
	var dir = to_target.normalized()
	
	if "velocity" in actor and "speed" in actor:
		actor.velocity = dir * (actor.speed * charge_speed_mult)
		actor.rotation = lerp_angle(actor.rotation, dir.angle(), 0.2)
		
	return RUNNING
