extends Node

class_name PickupSpawner

@export var weapon_scenes: Array[PackedScene] = []
@export var health_count: int = 20
@export var weapon_count: int = 20

func spawn_pickups(hex_map: Dictionary):
	if not multiplayer.is_server():
		return
	
	print("Spawning initial pickups...")
	var hex_keys = hex_map.keys()
	if hex_keys.is_empty():
		return
	
	# Find Pickups node in Game
	var pickups_node = get_tree().current_scene.find_child("Pickups", true, false)
	if not pickups_node:
		print("ERROR: Pickups node NOT FOUND in Game scene!")
		return

	# Spawn Weapons
	for i in range(weapon_count):
		if weapon_scenes.is_empty():
			break
		var coords = hex_keys[randi() % hex_keys.size()]
		var hex = hex_map[coords]
		var pos = hex.get_world_position()
		var w_scene = weapon_scenes[randi() % weapon_scenes.size()]
		_spawn_pickup("weapon", w_scene, pos, pickups_node)
		
	# Spawn Health
	for i in range(health_count):
		var coords = hex_keys[randi() % hex_keys.size()]
		var hex = hex_map[coords]
		var pos = hex.get_world_position()
		_spawn_pickup("health", null, pos, pickups_node)

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
	
	parent.add_child(pickup, true)
