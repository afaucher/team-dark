extends Node
class_name TeamDarkPathfinder

var astar := AStar2D.new()
var hex_to_id := {} # Vector2i -> int
var id_to_hex := {} # int -> Vector2i

func update_graph(hex_map: Dictionary):
	astar.clear()
	hex_to_id.clear()
	id_to_hex.clear()
	
	var id_counter = 0
	
	# 1. Add all nodes
	for coords in hex_map:
		hex_to_id[coords] = id_counter
		id_to_hex[id_counter] = coords
		var pos = hex_map[coords].get_world_position()
		astar.add_point(id_counter, pos)
		id_counter += 1
		
	# 2. Add edges based on height compatibility
	for coords in hex_map:
		var hex = hex_map[coords]
		var neighbors = hex.get_neighbors(hex.q, hex.r)
		var current_id = hex_to_id[coords]
		
		for n_coords in neighbors:
			if hex_map.has(n_coords):
				var neighbor = hex_map[n_coords]
				var n_id = hex_to_id[n_coords]
				
				# Physics rule: diff > 2 is a wall
				if abs(hex.height - neighbor.height) <= 2:
					astar.connect_points(current_id, n_id)

func get_path_to_world_pos(start_world: Vector2, end_world: Vector2) -> PackedVector2Array:
	var q_r_start = preload("res://scripts/hex_grid.gd").pixel_to_axial(start_world)
	var q_r_end = preload("res://scripts/hex_grid.gd").pixel_to_axial(end_world)
	
	if not hex_to_id.has(q_r_start) or not hex_to_id.has(q_r_end):
		return PackedVector2Array()
		
	var start_id = hex_to_id[q_r_start]
	var end_id = hex_to_id[q_r_end]
	
	return astar.get_point_path(start_id, end_id)

func is_reachable(start_world: Vector2, end_world: Vector2) -> bool:
	var path = get_path_to_world_pos(start_world, end_world)
	return path.size() > 0
