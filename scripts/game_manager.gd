extends Node

@export var map_generator_scene: PackedScene
@export var player_scene: PackedScene
@export var enemy_spawner_scene: PackedScene
@export var main_menu_scene: PackedScene
@export var hud_scene: PackedScene
@export var pickup_spawner_scene: PackedScene

var current_map = null
var current_seed: int = 0
var players_container = null

func _ready():
	# Configure Projectile Spawner
	var spawner = get_node_or_null("ProjectileSpawner")
	if spawner:
		spawner.add_spawnable_scene("res://scenes/projectiles/pellet.tscn")
	
	# Start with Main Menu
	_show_main_menu()
	
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	# Listen for connection success to request game state if needed?
	# For now, Server pushes state.

func _input(event):
	if event.is_action_pressed("quit_game"):
		get_tree().quit()

func _show_main_menu():
	var menu = main_menu_scene.instantiate()
	add_child(menu)

func start_game():
	# Called when server decides to start
	if current_map: return
	
	# Decide seed
	current_seed = randi()
	_load_map.rpc(current_seed)
	
	if not players_container:
		players_container = Node2D.new()
		players_container.name = "Players"
		add_child(players_container)

@rpc("authority", "call_local", "reliable")
func _load_map(seed_val: int):
	print("Loading map with seed: ", seed_val)
	current_seed = seed_val
	
	# Cleanup menu
	for child in get_children():
		if child is Control: # Assuming Menu/HUD are Controls
			child.queue_free()
	
	# Instantiate Map
	if map_generator_scene:
		var map_gen = map_generator_scene.instantiate()
		add_child(map_gen)
		current_map = map_gen
		# Access the internal generator node to set seed
		# Map scene structure: Map (Renderer) -> Generator (Node)
		var internal_gen = map_gen.get_node("Generator")
		if internal_gen:
			internal_gen.generate_map(current_seed)
			# Regenerate collisions for the synchronized map
			if map_gen.has_node("Physics"):
				map_gen.get_node("Physics").generate_collisions()
			# Trigger redraw on renderer
			map_gen.queue_redraw()
			
			# Spawn Pickups (Server only)
			if multiplayer.is_server() and pickup_spawner_scene:
				var spawner = pickup_spawner_scene.instantiate()
				add_child(spawner)
				if spawner.has_method("spawn_pickups"):
					spawner.spawn_pickups(internal_gen.hex_map)
			
	# Add HUD
	if hud_scene:
		var hud = hud_scene.instantiate()
		add_child(hud)

func _on_player_connected(id, info):
	if multiplayer.is_server():
		var spawn_pos = Vector2(100, 100) # Default
		
		# Proximity Spawning: Find an existing player to spawn near
		if players_container and players_container.get_child_count() > 0:
			var existing_players = players_container.get_children()
			var target = existing_players[randi() % existing_players.size()]
			# Random offset in a circle
			var offset = Vector2.from_angle(randf() * TAU) * randf_range(50, 150)
			spawn_pos = target.position + offset
		
		if current_map:
			_load_map.rpc_id(id, current_seed)
			_spawn_player.rpc(id, info, spawn_pos)
			
			for pid in NetworkManager.players:
				if pid != id:
					# We need to know where the existing player IS to spawn them correctly for the new guy
					# But MultiplayerSynchronizer will fix the position immediately after spawn.
					# For simplicity, just use their current position if available.
					var existing_p = players_container.get_node_or_null(str(pid))
					var p_pos = existing_p.position if existing_p else Vector2.ZERO
					_spawn_player.rpc_id(id, pid, NetworkManager.players[pid], p_pos)
		else:
			start_game()
			_spawn_player.rpc(id, info, spawn_pos)

@rpc("authority", "call_local", "reliable")
func _spawn_player(id, info, spawn_pos: Vector2):
	print("Spawning player: ", id, " at ", spawn_pos)
	if not players_container:
		players_container = Node2D.new()
		players_container.name = "Players"
		add_child(players_container)
		
	if players_container.has_node(str(id)):
		return

	var p = player_scene.instantiate()
	p.name = str(id)
	p.player_id = id
	p.position = spawn_pos
	players_container.add_child(p, true)

func _on_server_disconnected():
	# Cleanup and return to menu
	if current_map:
		current_map.queue_free()
		current_map = null
	if players_container:
		players_container.queue_free()
		players_container = null
	
	_show_main_menu()
