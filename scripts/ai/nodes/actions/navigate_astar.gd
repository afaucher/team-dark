extends "res://addons/beehave/nodes/leaves/action.gd"

## NavigateAStar Action
## Uses the PathfindingManager to navigate towards a target position.

@export var arrival_tolerance: float = 50.0

var current_path: PackedVector2Array = []
var path_index: int = 0
var target_pos: Vector2 = Vector2.ZERO

func tick(actor: Node, blackboard: Blackboard) -> int:
	var target = blackboard.get_value("target_pos")
	if not target:
		return FAILURE
		
	# Recalculate path if target changed significantly
	if target.distance_to(target_pos) > 100.0 or current_path.is_empty():
		target_pos = target
		_update_path(actor)
		
	if current_path.is_empty():
		return FAILURE
		
	if path_index >= current_path.size():
		return SUCCESS
		
	var next_point = current_path[path_index]
	var to_point = next_point - actor.global_position
	
	if to_point.length() < arrival_tolerance:
		path_index += 1
		if path_index >= current_path.size():
			return SUCCESS
		next_point = current_path[path_index]
		to_point = next_point - actor.global_position
		
	var dir = to_point.normalized()
	if "velocity" in actor and "speed" in actor:
		actor.velocity = dir * actor.speed
		actor.rotation = lerp_angle(actor.rotation, dir.angle(), 0.1)
		
	return RUNNING

func _update_path(actor: Node):
	var gm = get_tree().get_first_node_in_group("managers")
	if gm and gm.has_node("Pathfinding"):
		var pf = gm.get_node("Pathfinding")
		current_path = pf.get_path_to_world_pos(actor.global_position, target_pos)
		path_index = 0
