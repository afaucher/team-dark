extends "res://addons/beehave/nodes/leaves/action.gd"

## UseUtility Action
## Attempts to find and trigger a utility (Shield/Health) in the actor's weapon mounts.

@export var utility_type: String = "any" # "any", "shield", "health"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if not actor.has_method("_fire_all_weapons"):
		return FAILURE
		
	# In our architecture, utilities are treated as weapons in specific mounts or can be triggered at once
	# For enemies, we'll try to trigger all mounts that might contain a utility.
	# The 'held' logic depend on the utility type.
	
	actor._fire_all_weapons(true, true)
	return SUCCESS
