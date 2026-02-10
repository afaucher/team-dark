extends Node

class_name PickupSpawner

@export var weapon_scenes: Array[PackedScene] = []
@export var utility_scenes: Array[PackedScene] = []
@export var health_count: int = 5
@export var weapon_count: int = 5
@export var utility_count: int = 5
@export var gem_count: int = 3
@export var extraction_scene: PackedScene

func spawn_pickups(hex_map: Dictionary):
	# print("Spawning initial pickups...")
	var hex_keys = hex_map.keys()
	if hex_keys.is_empty():
		return
	
	# Find Pickups node in Game
	var pickups_node = get_tree().current_scene.find_child("Pickups", true, false)
	if not pickups_node:
		print("ERROR: Pickups node NOT FOUND in Game scene!")
		return

	# Track objective locations to ensure spread
	var existing_objectives: Array[Vector2] = []
	
	# Spawn Extraction Point (1) - Far from center
	if extraction_scene:
		var pos = _get_farthest_point(hex_map, existing_objectives, 20)
		existing_objectives.append(pos)
		
		var ext = extraction_scene.instantiate()
		ext.global_position = pos
		ext.name = "ExtractionPoint"
		pickups_node.add_child(ext, true)
		# print("Spawned Extraction Point at ", pos)

	# Spawn Remaining Gems - Far from extraction and center and each other
	for i in range(gem_count):
		var pos = _get_farthest_point(hex_map, existing_objectives, 20)
		existing_objectives.append(pos)
		_spawn_pickup("gem", null, pos, pickups_node)

	# Spawn Weapons (Random)
	for i in range(weapon_count):
		if weapon_scenes.is_empty():
			break
		var coords = hex_keys[randi() % hex_keys.size()]
		var hex = hex_map[coords]
		var pos = hex.get_world_position()
		var w_scene = weapon_scenes[randi() % weapon_scenes.size()]
		_spawn_pickup("weapon", w_scene, pos, pickups_node)
		
	# Spawn Utilities (Random)
	for i in range(utility_count):
		if utility_scenes.is_empty():
			break
		var coords = hex_keys[randi() % hex_keys.size()]
		var hex = hex_map[coords]
		var pos = hex.get_world_position()
		var u_scene = utility_scenes[randi() % utility_scenes.size()]
		_spawn_pickup("utility", u_scene, pos, pickups_node)
		
	# Spawn Health (Random)
	for i in range(health_count):
		var coords = hex_keys[randi() % hex_keys.size()]
		var hex = hex_map[coords]
		var pos = hex.get_world_position()
		_spawn_pickup("health", null, pos, pickups_node)

func _get_farthest_point(hex_map, existing_points: Array[Vector2], samples: int) -> Vector2:
	var keys = hex_map.keys()
	if keys.is_empty(): return Vector2.ZERO
	
	var best_pos = Vector2.ZERO
	var best_min_dist = -1.0
	
	# Try random candidates and pick the one with best separation
	for i in range(samples):
		var k = keys[randi() % keys.size()]
		var candidate_pos = hex_map[k].get_world_position()
		
		# Distance to center (0,0) is implicit objective to avoid
		var min_d = candidate_pos.length() 
		
		for p in existing_points:
			var d = candidate_pos.distance_to(p)
			if d < min_d:
				min_d = d
		
		if min_d > best_min_dist:
			best_min_dist = min_d
			best_pos = candidate_pos
			
	return best_pos

func _spawn_pickup(type: String, scene: PackedScene, pos: Vector2, parent: Node):
	var pickup_pkg = load("res://scenes/objects/pickup.tscn")
	var pickup = pickup_pkg.instantiate()
	pickup.pickup_type = type
	pickup.item_scene = scene
	if scene:
		pickup.item_scene_path = scene.resource_path
	pickup.global_position = pos
	
	if type == "weapon" and scene:
		var temp = scene.instantiate()
		pickup.pickup_name = temp.weapon_name if "weapon_name" in temp else "Weapon"
		temp.free()
	elif type == "health":
		pickup.pickup_name = "Health Kit"
	elif type == "utility" and scene:
		var temp = scene.instantiate()
		pickup.pickup_name = temp.utility_name if "utility_name" in temp else "Utility"
		temp.free()
	elif type == "gem":
		pickup.pickup_name = "Power Gem"
		
	parent.add_child(pickup, true)
