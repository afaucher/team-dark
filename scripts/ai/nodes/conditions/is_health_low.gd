extends "res://addons/beehave/nodes/leaves/condition.gd"

## IsHealthLow Condition
## Succeeds if the actor's health is below a certain percentage.

@export var threshold_percent: float = 0.3

func tick(actor: Node, blackboard: Blackboard) -> int:
	if "current_hp" in actor and "max_hp" in actor:
		if actor.current_hp / actor.max_hp < threshold_percent:
			return SUCCESS
	return FAILURE
