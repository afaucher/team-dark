extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	var player = actor
	
	# Find GameManager
	var gm = get_tree().current_scene
	if not gm:
		return FAILURE
	
	var target_pos = Vector2.ZERO
	var has_target = false
	
	var collected = gm.get("collected_gems") if "collected_gems" in gm else 0
	var max_gems = gm.get("MAX_GEMS") if "MAX_GEMS" in gm else 3
	
	if collected < max_gems:
		# Check "gems" group first
		var gems = get_tree().get_nodes_in_group("gems")
		
		# Fallback: check all pickups and filter for gems
		if gems.size() == 0:
			var pickups = get_tree().get_nodes_in_group("pickups")
			for p in pickups:
				if "pickup_type" in p and p.pickup_type == "gem":
					gems.append(p)
		
		var min_dist = INF
		var nearest_gem = null
		
		for gem in gems:
			var d = player.global_position.distance_to(gem.global_position)
			if d < min_dist:
				min_dist = d
				nearest_gem = gem
		
		if nearest_gem:
			target_pos = nearest_gem.global_position
			has_target = true
	else:
		var extraction = get_tree().current_scene.find_child("ExtractionPoint", true, false)
		if extraction:
			target_pos = extraction.global_position
			has_target = true

	if has_target:
		blackboard.set_value("mission_target_pos", target_pos)
		return SUCCESS
	
	return FAILURE
