extends "res://addons/beehave/nodes/leaves/action.gd"

## FindPlayerTarget Action
## Finds the nearest player and stores their position in the blackboard.

func tick(actor: Node, blackboard: Blackboard) -> int:
	var players = get_tree().get_nodes_in_group("players")
	var nearest = null
	var min_d = INF
	
	for p in players:
		var d = actor.global_position.distance_to(p.global_position)
		if d < min_d:
			min_d = d
			nearest = p
			
	if nearest:
		blackboard.set_value("target_pos", nearest.global_position)
		blackboard.set_value("nearest_player", nearest)
		if "target_node" in actor:
			actor.target_node = nearest
		return SUCCESS
		
	return FAILURE
