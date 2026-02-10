extends "res://addons/beehave/nodes/leaves/action.gd"

## FleePlayer Action
## Moves the actor away from the nearest player in the 'players' group.

@export var flee_distance: float = 600.0

func tick(actor: Node, blackboard: Blackboard) -> int:
	var nearest_player = null
	var min_dist = flee_distance
	
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		var d = actor.global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			nearest_player = p
			
	if not nearest_player:
		return FAILURE
		
	var dir_away = (actor.global_position - nearest_player.global_position).normalized()
	
	# We assume the actor has a 'velocity' or 'move_vector' property
	# For enemies using basic physics logic:
	if actor.has_method("move_and_slide") or "velocity" in actor:
		if "speed" in actor:
			actor.velocity = dir_away * actor.speed
			actor.rotation = lerp_angle(actor.rotation, dir_away.angle(), 0.1)
		
	return RUNNING
