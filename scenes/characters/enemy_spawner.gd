extends Node
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var cluster_count: int = 10
@export var solo_count: int = 15

var rng = RandomNumberGenerator.new()

func spawn_enemies(hex_map: Dictionary):
	if not multiplayer.is_server(): return
	
	print("Spawning enemies...")
	var hex_keys = hex_map.keys()
	if hex_keys.is_empty(): return
	
	# Choose a unique color theme for this round
	# (Avoiding common UI colors like Cyan/Red/Yellow if possible, or just vivid random)
	var round_color = Color.from_hsv(rng.randf(), 0.8, 1.0)
	
	var enemies_node = get_tree().current_scene.find_child("Enemies", true, false)
	if not enemies_node:
		print("ERROR: Enemies node NOT FOUND in Game scene!")
		return

	# 1. Spawn Clusters (Scouts)
	for i in range(cluster_count):
		var center_pos = _get_random_flat_pos(hex_map, hex_keys)
		_spawn_cluster(center_pos, round_color, enemies_node)

	# 2. Spawn Solo (Heavies)
	for i in range(solo_count):
		var pos = _get_random_flat_pos(hex_map, hex_keys)
		_spawn_enemy(pos, 2, round_color, enemies_node) # 2 = HEAVY

	# 3. Spawn Basic (Gray/Easy) everywhere else
	for i in range(solo_count):
		var pos = _get_random_flat_pos(hex_map, hex_keys)
		_spawn_enemy(pos, 0, Color.GRAY, enemies_node) # 0 = EASY
		
	# 4. Spawn Swarm!
	for i in range(12): # 12 tiny swarms
		var pos = _get_random_flat_pos(hex_map, hex_keys)
		_spawn_enemy(pos, 3, Color.LIME_GREEN, enemies_node) # 3 = SWARM

func _get_random_flat_pos(hex_map, keys) -> Vector2:
	# Try a few times to find a "safe" reachable spot? 
	# For now just pick random hex.
	var key = keys[rng.randi() % keys.size()]
	return hex_map[key].get_world_position()

func _spawn_cluster(center: Vector2, color: Color, parent: Node):
	var size = rng.randi_range(3, 5)
	for i in range(size):
		var offset = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * rng.randf_range(20, 100)
		_spawn_enemy(center + offset, 1, color, parent) # 1 = SCOUT

func _spawn_enemy(pos: Vector2, tier: int, color: Color, parent: Node):
	var r = rng.randf()
	var chosen_scene: PackedScene = null
	
	match tier:
		0: # EASY / BASIC
			chosen_scene = preload("res://scenes/characters/easy_enemy.tscn")
		1: # SCOUT / CLUSTER
			if r < 0.3: chosen_scene = preload("res://scenes/characters/skittish_enemy.tscn")
			elif r < 0.6: chosen_scene = preload("res://scenes/characters/kamikaze_enemy.tscn")
			else: chosen_scene = preload("res://scenes/characters/scout_enemy.tscn")
		2: # HEAVY
			if r < 0.4: chosen_scene = preload("res://scenes/characters/mortar_enemy.tscn")
			else: chosen_scene = preload("res://scenes/characters/heavy_enemy.tscn")
		3: # SWARM (New tier)
			chosen_scene = preload("res://scenes/characters/swarm_enemy.tscn")
			
	if not chosen_scene: return
	
	var enemy = chosen_scene.instantiate()
	if "color_theme" in enemy:
		enemy.color_theme = color
	
	# Add to tree BEFORE setting position for some synchronization types
	parent.add_child(enemy, true)
	enemy.global_position = pos
