extends Node2D

const HexGrid = preload("res://scripts/hex_grid.gd")

@export var map_generator: Node
@export var base_color: Color = Color("#050510") # ThemeManager.bg_void proxy
@export var light_color: Color = Color("#7000FF") # ThemeManager.grid_main proxy
@export var dark_color: Color = Color.BLACK 
@export var cliff_color: Color = Color("#00FFFF") # ThemeManager.player_primary proxy for highlights

@export var outline_color: Color = Color("#00FFFF") 
@export var outline_width: float = 1.5

@onready var map_physics = $Physics

var current_baseline: float = 0.0
var target_baseline: float = 0.0

func _ready():
	# Apply Theme
	base_color = ThemeManager.bg_void
	light_color = ThemeManager.grid_main.lightened(0.2)
	outline_color = ThemeManager.player_primary
	
	if not map_generator:
		map_generator = get_node_or_null("Generator")
	
	if map_generator:
		map_generator.generate_map() # Initial generation
		if map_physics:
			map_physics.generate_collisions()
		queue_redraw()

func _input(event):
	if event.is_action_pressed("toggle_debug"):
		queue_redraw()

var last_cam_pos: Vector2 = Vector2.ZERO

func _process(delta):
	# Find local player to set baseline
	var local_player = _get_local_player()
	if local_player:
		var player_pos = local_player.position
		var hex_coords = HexGrid.pixel_to_axial(player_pos)
		if map_generator and map_generator.hex_map.has(hex_coords):
			target_baseline = float(map_generator.hex_map[hex_coords].height)
	
	# Smooth fade - Lerp towards target
	var baseline_changed = false
	if abs(current_baseline - target_baseline) > 0.01:
		current_baseline = lerp(current_baseline, target_baseline, delta * 5.0)
		baseline_changed = true
	
	# Redraw if camera moved (for culling) or baseline changed
	var cam = get_viewport().get_camera_2d()
	if cam:
		var cam_pos = cam.get_screen_center_position()
		if cam_pos != last_cam_pos or baseline_changed:
			last_cam_pos = cam_pos
			queue_redraw()
	elif baseline_changed:
		queue_redraw()

func _get_local_player():
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p.is_multiplayer_authority():
			return p
	return null

func _draw():
	if not map_generator or map_generator.hex_map.is_empty():
		return

	# Culling Logic
	var viewport_rect = get_viewport_rect()
	var cam = get_viewport().get_camera_2d()
	var visible_rect: Rect2
	
	if cam:
		var cam_center = cam.get_screen_center_position()
		var cam_size = viewport_rect.size / cam.zoom
		visible_rect = Rect2(cam_center - cam_size/2.0, cam_size)
	else:
		visible_rect = viewport_rect

	var buffered_rect = visible_rect.grow(HexGrid.HEX_SIZE * 2.0)
	
	var top_left = buffered_rect.position
	var bottom_right = buffered_rect.end
	
	var q_min = floor((2.0/3.0 * top_left.x) / HexGrid.HEX_SIZE) - 1
	var q_max = ceil((2.0/3.0 * bottom_right.x) / HexGrid.HEX_SIZE) + 1
	
	var corners = [
		top_left, 
		Vector2(bottom_right.x, top_left.y), 
		Vector2(top_left.x, bottom_right.y), 
		bottom_right
	]
	var r_min = 1e9
	var r_max = -1e9
	
	for p in corners:
		var r_val = (-1.0/3.0 * p.x + sqrt(3.0)/3.0 * p.y) / HexGrid.HEX_SIZE
		r_min = min(r_min, r_val)
		r_max = max(r_max, r_val)
	
	r_min = floor(r_min) - 1
	r_max = ceil(r_max) + 1

	for q in range(q_min, q_max + 1):
		for r in range(r_min, r_max + 1):
			var coords = Vector2i(q, r)
			if map_generator.hex_map.has(coords):
				_draw_hex(map_generator.hex_map[coords])

func _draw_hex(hex):
	var center = HexGrid.axial_to_pixel(hex.q, hex.r)
	var radius = HexGrid.HEX_SIZE - 2 
	
	var points = PackedVector2Array()
	for i in range(6):
		var angle_deg = 60 * i 
		var angle_rad = deg_to_rad(angle_deg)
		points.append(center + Vector2(cos(angle_rad), sin(angle_rad)) * radius)
	
	var diff = float(hex.height) - current_baseline
	var color = base_color
	
	var clamped_diff = clamp(diff, -4.0, 4.0)
	var intensity_factor = 0.25 
	
	if clamped_diff > 0:
		var t = (clamped_diff / 4.0) * intensity_factor
		color = base_color.lerp(light_color, t)
	elif clamped_diff < 0:
		var t = (abs(clamped_diff) / 4.0) * intensity_factor
		color = base_color.lerp(dark_color, t)
		
	draw_colored_polygon(points, color)
	
	var neighbors = HexGrid.get_neighbors(hex.q, hex.r)
	var faded_color = outline_color * Color(1, 1, 1, 0.1)
	
	var edge_to_neighbor_idx = [0, 5, 4, 3, 2, 1]
	var show_debug = DebugManager.show_debug
	
	for i in range(6):
		var n_idx = edge_to_neighbor_idx[i]
		var neigh_coords = neighbors[n_idx]
		var neighbor = map_generator.hex_map.get(neigh_coords)
		
		var is_cliff = false
		if neighbor == null:
			is_cliff = true 
		else:
			var h_diff = abs(hex.height - neighbor.height)
			if h_diff > 2:
				is_cliff = true
		
		var p1 = points[i]
		var p2 = points[(i + 1) % 6]
		
		if is_cliff:
			draw_line(p1, p2, outline_color, outline_width * 1.5)
		else:
			draw_line(p1, p2, faded_color, outline_width)
			
	if show_debug:
		draw_string(ThemeDB.fallback_font, center, "H:" + str(hex.height), HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.WHITE)
