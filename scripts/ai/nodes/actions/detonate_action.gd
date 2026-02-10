extends ActionLeaf

## DetonateAction
## Triggers the enemy's detonation logic if a player is in range.

@export var detonation_range: float = 60.0

func tick(actor: Node, blackboard: Blackboard) -> int:
	if not actor.has_method("detonate"):
		return FAILURE
		
	var target = blackboard.get_value("nearest_player")
	if not is_instance_valid(target):
		return FAILURE
		
	var dist = actor.global_position.distance_to(target.global_position)
	if dist <= detonation_range:
		actor.detonate()
		return SUCCESS
		
	return FAILURE
