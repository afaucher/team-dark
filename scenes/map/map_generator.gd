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
	# Increased weight of warping and main noise frequency to force more cliffs
	var warp_scale = 12.0
	var warp_x = noise.get_noise_2d(q * warp_scale, r * warp_scale) * 20.0
	var warp_y = noise.get_noise_2d(r * warp_scale, q * warp_scale) * 20.0
	
	# Main noise - Higher multiplier = more frequent changes / smaller plateaus
	var main_freq = 6.0
	var value = noise.get_noise_2d(q * main_freq + warp_x, r * main_freq + warp_y)
	
	# Normalize to 0..1
	value = (value + 1.0) / 2.0
	
	# Quantize into steps (0 to 24)
	# A jump of > 2 in this result will create a cliff.
	var total_height = value * 24.0
	return int(total_height)
