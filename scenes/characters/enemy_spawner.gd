extends Node
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var cluster_count: int = 15
@export var solo_count: int = 25

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
		_spawn_enemy(pos, Enemy.Tier.HEAVY, round_color, enemies_node)

	# 3. Spawn Basic (Gray/Easy) everywhere else
	for i in range(20):
		var pos = _get_random_flat_pos(hex_map, hex_keys)
		_spawn_enemy(pos, Enemy.Tier.EASY, Color.GRAY, enemies_node)

func _get_random_flat_pos(hex_map, keys) -> Vector2:
	# Try a few times to find a "safe" reachable spot? 
	# For now just pick random hex.
	var key = keys[rng.randi() % keys.size()]
	return hex_map[key].get_world_position()

func _spawn_cluster(center: Vector2, color: Color, parent: Node):
	var size = rng.randi_range(3, 5)
	for i in range(size):
		var offset = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * rng.randf_range(20, 100)
		_spawn_enemy(center + offset, Enemy.Tier.SCOUT, color, parent)

func _spawn_enemy(pos: Vector2, tier: Enemy.Tier, color: Color, parent: Node):
	if not enemy_scene: return
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	enemy.tier = tier
	enemy.color_theme = color
	parent.add_child(enemy, true)
