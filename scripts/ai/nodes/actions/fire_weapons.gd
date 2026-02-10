extends ActionLeaf

## FireWeapons
## Action to trigger all equipped weapons on the actor.

@export var fire_continuous: bool = true
@export var max_distance: float = 800.0

func tick(actor: Node, blackboard: Blackboard) -> int:
	if not actor.has_method("_fire_all_weapons"):
		return FAILURE
		
	# Check distance to target if available in blackboard
	var target = blackboard.get_value("nearest_player")
	if is_instance_valid(target):
		var dist = actor.global_position.distance_to(target.global_position)
		if dist > max_distance:
			return FAILURE
	
	# In a real game, we might check line of sight here or via a separate condition node.
	# For now, if this node is leaf-ticked in a sequence, we assume the AI wants to fire.
	
	actor._fire_all_weapons(true, fire_continuous)
	return SUCCESS
