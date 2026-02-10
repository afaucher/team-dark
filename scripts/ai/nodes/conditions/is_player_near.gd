extends "res://addons/beehave/nodes/leaves/condition.gd"

## IsPlayerNear Condition
## Succeeds if any player is within the specified distance.

@export var distance: float = 500.0

func tick(actor: Node, blackboard: Blackboard) -> int:
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if actor.global_position.distance_to(p.global_position) < distance:
			blackboard.set_value("nearest_player", p)
			return SUCCESS
	return FAILURE
