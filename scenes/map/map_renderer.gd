extends Node2D

const HexGrid = preload("res://scripts/hex_grid.gd")

@export var map_generator: Node
@export var hex_color_palette: Array[Color] = [
	Color("#1a1a2e"), # Low (Charcoal)
	Color("#16213e"), # Med (Deep Blue)
	Color("#0f3460"), # High (Muted Blue)
	Color("#e94560")  # Obstacle/Peak (Red/Pink)
]
@export var outline_color: Color = Color("#00fff5") # Cyan
@export var outline_width: float = 2.0

func _ready():
	if not map_generator:
		map_generator = get_node_or_null("Generator")
	
	if map_generator:
		map_generator.generate_map() # Initial generation
		queue_redraw()

func _draw():
	if not map_generator or map_generator.hex_map.is_empty():
		return

	for hex in map_generator.hex_map.values():
		_draw_hex(hex)

func _draw_hex(hex):
	var center = HexGrid.axial_to_pixel(hex.q, hex.r)
	var radius = HexGrid.HEX_SIZE - 2 # Mild padding
	
	# Create points for a hexagon
	var points = PackedVector2Array()
	for i in range(6):
		var angle_deg = 60 * i # Flat-topped (0, 60, 120...)
		var angle_rad = deg_to_rad(angle_deg)
		points.append(center + Vector2(cos(angle_rad), sin(angle_rad)) * radius)
	
	# Draw filled hex (Color based on height)
	var color_idx = clampi(hex.height, 0, hex_color_palette.size() - 1)
	draw_colored_polygon(points, hex_color_palette[color_idx])
	
	# Draw outline
	points.append(points[0]) # Close the loop
	draw_polyline(points, outline_color, outline_width)
