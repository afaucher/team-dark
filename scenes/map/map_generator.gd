extends Node
class_name MapGenerator

@export var map_radius: int = 50
@export var noise: FastNoiseLite

const HexGrid = preload("res://scripts/hex_grid.gd")

var hex_map: Dictionary = {} # Vector2i(q, r) -> HexGrid
var map_seed: int = 0

func generate_map(custom_seed: int = 0):
	hex_map.clear()
	if not noise:
		noise = FastNoiseLite.new()
	
	if custom_seed != 0:
		map_seed = custom_seed
	elif map_seed == 0:
		map_seed = randi()
		
	noise.seed = map_seed
	
	for q in range(-map_radius, map_radius + 1):
		var r1 = max(-map_radius, -q - map_radius)
		var r2 = min(map_radius, -q + map_radius)
		for r in range(r1, r2 + 1):
			var height = _get_height(q, r)
			var hex = HexGrid.new(q, r, height)
			hex_map[Vector2i(q, r)] = hex

	return hex_map

func _get_height(q: int, r: int) -> int:
	# Use noise to generate height steps (0, 1, 2...)
	var value = noise.get_noise_2d(q * 10, r * 10)
	# Normalize and step
	if value < -0.2: return 0
	if value < 0.2: return 1
	if value < 0.5: return 2
	return 3
