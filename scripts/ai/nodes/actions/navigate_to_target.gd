extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	var player = actor
	var controller = player.ai_controller
	
	if not blackboard.has_value("mission_target_pos"):
		return FAILURE
		
	var target_pos = blackboard.get_value("mission_target_pos")
	var to_target = target_pos - player.global_position
	var dist = to_target.length()
	
	if dist < 50.0:
		controller.move_vector = Vector2.ZERO
		return SUCCESS
		
	var dir = to_target.normalized()
	controller.move_vector = dir
	
	if not blackboard.get_value("is_combatting", false):
		controller.aim_vector = dir
		
	return RUNNING
