extends Node2D

@export var map_generator: Node

const HexGrid = preload("res://scripts/hex_grid.gd")

func _ready():
	if not map_generator:
		map_generator = get_node_or_null("../Generator")

func generate_collisions():
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	queue_redraw() # For debug visuals
	
	if not map_generator or map_generator.hex_map.is_empty():
		return

	var blocking_body = StaticBody2D.new()
	blocking_body.name = "MapBoundaries"
	add_child(blocking_body)
	
	for coords in map_generator.hex_map:
		var hex = map_generator.hex_map[coords]
		_process_hex_edges(blocking_body, hex)

func _process_hex_edges(body: StaticBody2D, hex: RefCounted):
	var neighbors = HexGrid.get_neighbors(hex.q, hex.r)
	
	# Hex corners calculation (Flat-topped: angles 0, 60, 120, 180, 240, 300)
	# Neighbor 0 (East, +1, 0) corresponds to edge between corner 5 (-60/300) and 0 (0) ? 
	# Let's verify standard flat-topped neighbor order vs angles.
	# Neighbors usually: E, SE, SW, W, NW, NE
	# Flat top angles: 0, 60, 120, 180, 240, 300.
	# E neighbor is at 0 degrees. Edge is between 300(-60) and 60? No, that faces East.
	# Actually flat topped hex:
	#       / \
	#     |     |
	#       \ /
	# Points are at 0, 60, 120...
	# Edge 0 (East): Connects Point 5 (300deg) and Point 0 (0deg)? Wait.
	# Point 0 is at (R, 0). Point 1 is at (R/2, R*sqrt(3)/2).
	# East neighbor is at (1.5*R, sqrt(3)/2*R) ?? No.
	# Let's assume standard lookup or calculate based on relative position.
	
	# For simplicity: Calculate center of Hex and Neighbor. Edge is the perpendicular bisector segment?
	# Better: shared vertices. 
	# Vertex k is at angle k*60.
	# Edge k connects Vertex k and (k+1)%6.
	# Neighbor k is in the direction perpendicular to Edge k.
	# Flat topped neighbors (axial):
	# 0: (+1, 0)   -> East.       Edge should be vertices 5 and 0? (300 and 0 deg? No, that faces +X, -Y somewhat).
	# 1: (+1, -1)  -> North East. Edge vertices 0 and 1?
	# 2: (0, -1)   -> North West. Edge vertices 1 and 2?
	# 3: (-1, 0)   -> West.       Edge vertices 2 and 3?
	# 4: (-1, 1)   -> South West. Edge vertices 3 and 4?
	# 5: (0, 1)    -> South East. Edge vertices 4 and 5?
	
	for i in range(6):
		var n_coords = neighbors[i]
		var neighbor = map_generator.hex_map.get(n_coords)
		
		var should_block = false
		
		if neighbor == null:
			# Map Edge - Always block
			should_block = true
		else:
			# Internal Edge
			# Optimization: Only process if we are the "canonical" side (e.g., hash or coords compare)
			# UNLESS we treat walls as one-sided (which works for segments)
			# But we want to avoid double segments.
			# Let's verify canonical order: only build if we are 'smaller'
			var is_canonical = (hex.q < n_coords.x) or (hex.q == n_coords.x and hex.r < n_coords.y)
			
			if is_canonical:
				var diff = abs(hex.height - neighbor.height)
				if diff > 2: # "Step difference of more then 2 means player cannot cross"
					should_block = true
		
		if should_block:
			_add_edge_collision(body, hex, i)

func _add_edge_collision(body: Node, hex: RefCounted, edge_index: int):
	var center = HexGrid.axial_to_pixel(hex.q, hex.r)
	var r = HexGrid.HEX_SIZE
	
	# Map edge index (Neighbor Index) to vertex indices
	# Neighbors in HexGrid.gd: 0:E, 1:NE, 2:NW, 3:W, 4:SW, 5:SE
	# Vertices: 0:0deg, 1:60deg, 2:120deg, 3:180deg, 4:240deg, 5:300deg
	# Pt 0: (R,0). Pt 1: (BR). Pt 2: (BL). Pt 3: (L). Pt 4: (TL). Pt 5: (TR).
	
	# E Edge (0) -> Pt 5 to Pt 0
	# NE Edge (1) -> Pt 4 to Pt 5
	# NW Edge (2) -> Pt 3 to Pt 4
	# W Edge (3) -> Pt 2 to Pt 3
	# SW Edge (4) -> Pt 1 to Pt 2
	# SE Edge (5) -> Pt 0 to Pt 1
	var edge_vertex_map = [
		[0, 1], # 0: SE
		[5, 0], # 1: NE
		[4, 5], # 2: N
		[3, 4], # 3: NW
		[2, 3], # 4: SW
		[1, 2]  # 5: S
	]
	
	var indices = edge_vertex_map[edge_index]
	var v1_idx = indices[0]
	var v2_idx = indices[1]
	
	var start_angle_deg = 60 * v1_idx
	var end_angle_deg = 60 * v2_idx
	
	var p1 = center + Vector2(cos(deg_to_rad(start_angle_deg)), sin(deg_to_rad(start_angle_deg))) * r
	var p2 = center + Vector2(cos(deg_to_rad(end_angle_deg)), sin(deg_to_rad(end_angle_deg))) * r
	
	var shape = CollisionShape2D.new()
	var segment = SegmentShape2D.new()
	segment.a = p1
	segment.b = p2
	shape.shape = segment
	body.add_child(shape)
	queue_redraw()

func _draw():
	# Visualization of COLLIDERS (Physics Reality)
	# This should match the CYAN lines in MapRenderer
	var renderer = get_node_or_null("../")
	if not renderer or not renderer.get("show_debug"):
		return
		
	for body in get_children():
		if body is StaticBody2D:
			for shape_node in body.get_children():
				if shape_node is CollisionShape2D and shape_node.shape is SegmentShape2D:
					var seg = shape_node.shape
					draw_line(seg.a, seg.b, Color.MAGENTA, 4.0)
