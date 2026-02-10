extends Node

var SyncClass = load("res://addons/godot_rl_agents/sync.gd")
var PlayerScene = preload("res://scenes/characters/player.tscn")
var MapScene = preload("res://scenes/map/map.tscn")
var RLControllerScript = preload("res://scripts/ai/controllers/player_rl_controller.gd")
var HUDScene = preload("res://scenes/ui/hud.tscn")
var PickupSpawnerScene = preload("res://scenes/objects/pickup_spawner.tscn")
var EnemyScene = preload("res://scenes/characters/enemy.tscn")
var PathfinderClass = preload("res://scripts/training/pathfinding_manager.gd")

var sync_node
var map_node
var pathfinding: Node
var player
var collected_gems: int = 0
const MAX_GEMS: int = 10
var current_level: int = 1
var enemy_count: int = 100
var combat_damage_record: Dictionary = {} # player_id: float
var combat_kill_record: Dictionary = {} # player_id: int
var pickup_record: Dictionary = {} # player_id: int
var total_steps: int = 0

func _ready():
	add_to_group("managers")
	print("[Training] Starting Training Manager...")
	var args = _get_args()
	
	pathfinding = PathfinderClass.new()
	pathfinding.name = "Pathfinding"
	add_child(pathfinding)
	
	map_node = MapScene.instantiate()
	add_child(map_node)
	
	# Add HUD
	var hud = HUDScene.instantiate()
	hud.name = "HUD"
	add_child(hud)
	
	# Add Pickups Container (Expected by PickupSpawner)
	var pickups = Node2D.new()
	pickups.name = "Pickups"
	add_child(pickups)
	
	# 1. Initialize Level (Spawns Pickups and Enemies)
	reset_level()
	
	# 2. Spawn Player (Synchronously)
	# Important: Player must be in tree before Sync node initializes its agents list.
	_spawn_player()
	
	# 3. Add Sync Node (Godot RL Agents)
	sync_node = SyncClass.new()
	sync_node.name = "Sync"
	
	# Parse CLI args for inference
	if args.has("inference"):
		print("[TrainingManager] Running in INFERENCE mode.")
		sync_node.control_mode = 2 
		
		# Set model path
		var model_path = args.get("model_path", "res://models/policy.onnx")
		sync_node.onnx_model_path = model_path
		print("[TrainingManager] Using ONNX model: ", model_path)
	else:
		sync_node.control_mode = 1 # TRAINING
		sync_node.speedup = 20.0 # Default speedup for training

	add_child(sync_node)
	
func _get_args():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			arguments[argument.lstrip("--")] = ""
	return arguments

func _spawn_player():
	if player:
		player.queue_free()
		
	player = PlayerScene.instantiate()
	player.name = "1" 
	player.player_id = 1
	player.set_multiplayer_authority(1)
	
	add_child(player)
	player.global_position = Vector2(0, 0)

	if "ai_mode" in player:
		player.ai_mode = 2 # AIMode.TRAINED
	
	var controller = RLControllerScript.new()
	controller.name = "AIController"
	player.add_child(controller)
	
	if "ai_controller" in player:
		player.ai_controller = controller

func increment_gem_count():
	collected_gems += 1
	print("[Training] Gem Collected! Total: ", collected_gems)
	var hud = get_node_or_null("HUD")
	if hud and hud.has_method("update_gems"):
		hud.update_gems(collected_gems, MAX_GEMS)

func reset_level():
	collected_gems = 0
	
	# Clear Pickups and Enemies
	var pickups = get_node_or_null("Pickups")
	if pickups:
		for child in pickups.get_children():
			child.queue_free()
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	
	# Regenerate Map or just reshuffle pickups
	var internal_gen = map_node.get_node("Generator") if map_node else null
	if internal_gen:
		var spawner = get_node_or_null("PickupSpawner")
		if spawner:
			spawner.queue_free()
		
		spawner = PickupSpawnerScene.instantiate()
		spawner.name = "PickupSpawner"
		add_child(spawner)
		if spawner.has_method("spawn_pickups"):
			spawner.spawn_pickups(internal_gen.hex_map)
			
		# Update pathfinding graph
		if pathfinding:
			pathfinding.update_graph(internal_gen.hex_map)
	
	total_steps += 8000
	
	# Spawn Enemies for Level 2+
	print("[TrainingManager] Spawning ", enemy_count, " enemies...")
	if enemy_count > 0 and internal_gen:
		var hex_keys = internal_gen.hex_map.keys()
		
		# Pre-filter reachable hexes
		var reachable_hex_keys = []
		for coords in hex_keys:
			if pathfinding and pathfinding.has_method("is_reachable"):
				if pathfinding.is_reachable(Vector2.ZERO, internal_gen.hex_map[coords].get_world_position()):
					reachable_hex_keys.append(coords)
		
		if reachable_hex_keys.size() == 0:
			reachable_hex_keys = hex_keys 

		for i in range(enemy_count):
			var coords = reachable_hex_keys[randi() % reachable_hex_keys.size()]
			var hex = internal_gen.hex_map[coords]
			var enemy_scenes = [
				preload("res://scenes/characters/easy_enemy.tscn"),
				preload("res://scenes/characters/scout_enemy.tscn"),
				preload("res://scenes/characters/heavy_enemy.tscn"),
				preload("res://scenes/characters/skittish_enemy.tscn"),
				preload("res://scenes/characters/mortar_enemy.tscn"),
				preload("res://scenes/characters/kamikaze_enemy.tscn")
			]
			var e_scene = enemy_scenes[randi() % enemy_scenes.size()]
			var enemy = e_scene.instantiate()
			enemy.global_position = hex.get_world_position()
			add_child(enemy)
			enemy.enemy_damaged.connect(_on_enemy_damaged)
			enemy.enemy_killed.connect(_on_enemy_killed)
			enemy.add_to_group("enemies") 
	
	var hud = get_node_or_null("HUD")
	if hud and hud.has_method("update_gems"):
		hud.update_gems(0, MAX_GEMS)
	
	if player:
		if player.has_method("respawn"):
			player.respawn(Vector2.ZERO)
		else:
			player.global_position = Vector2.ZERO
			if "current_hp" in player:
				player.current_hp = player.max_hp
			if "is_dead" in player:
				player.is_dead = false
		_randomize_player_loadout(player)
	
	combat_damage_record.clear()
	combat_kill_record.clear()
	pickup_record.clear()

func _randomize_player_loadout(p: Node):
	var weapons = [
		"res://scenes/weapons/pellet_gun.tscn",
		"res://scenes/weapons/machine_gun.tscn",
		"res://scenes/weapons/shotgun.tscn"
	]
	
	var utilities = [
		"res://scenes/utility/shield.tscn",
		"res://scenes/utility/jump_pack.tscn"
	]
	
	if p.has_method("drop_weapon"):
		for i in range(3):
			p.drop_weapon(i)
	
	if p.has_method("equip_weapon"):
		# Always equip one random weapon (Mount 0)
		var w_path = weapons[randi() % weapons.size()]
		p.equip_weapon(0, w_path)
		
		# 30% chance to spawn with a utility/health item in Mount 1 or 2
		if randf() < 0.3:
			var slot = 1 + (randi() % 2)
			var u_path = utilities[randi() % utilities.size()]
			p.equip_weapon(slot, u_path)

func _on_enemy_damaged(amount: float, attacker_id: int):
	combat_damage_record[attacker_id] = combat_damage_record.get(attacker_id, 0.0) + amount

func _on_enemy_killed(attacker_id: int):
	combat_kill_record[attacker_id] = combat_kill_record.get(attacker_id, 0) + 1

func consume_combat_metrics(attacker_id: int) -> Dictionary:
	var dmg = combat_damage_record.get(attacker_id, 0.0)
	var kills = combat_kill_record.get(attacker_id, 0)
	var pickups = pickup_record.get(attacker_id, 0)
	
	combat_damage_record[attacker_id] = 0.0
	combat_kill_record[attacker_id] = 0
	pickup_record[attacker_id] = 0
	
	return {"damage": dmg, "kills": kills, "pickups": pickups}

func record_pickup(player_id: int, _type: String):
	pickup_record[player_id] = pickup_record.get(player_id, 0) + 1

func on_player_died(player_id: int):
	print("[Training] Player ", player_id, " died. Respawning in 3s...")
	await get_tree().create_timer(3.0).timeout
	
	if player and is_instance_valid(player):
		player.respawn.rpc(Vector2.ZERO)
		_randomize_player_loadout(player)
