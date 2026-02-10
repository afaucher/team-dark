extends "res://addons/beehave/nodes/leaves/action.gd"

@export var attack_range: float = 600.0

func tick(actor: Node, blackboard: Blackboard) -> int:
	var player = actor
	var controller = player.ai_controller
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var min_dist = attack_range
	var nearest_enemy = null
	
	for enemy in enemies:
		var d = player.global_position.distance_to(enemy.global_position)
		if d < min_dist:
			min_dist = d
			nearest_enemy = enemy
			
	if nearest_enemy:
		var to_enemy = nearest_enemy.global_position - player.global_position
		controller.aim_vector = to_enemy.normalized()
		controller.fire_all_held = true
		blackboard.set_value("is_combatting", true)
		return SUCCESS
	
	blackboard.set_value("is_combatting", false)
	return FAILURE
