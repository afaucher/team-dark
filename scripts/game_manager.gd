extends Node

@export var map_generator_scene: PackedScene
@export var player_scene: PackedScene
@export var enemy_spawner_scene: PackedScene
@export var main_menu_scene: PackedScene
@export var hud_scene: PackedScene

var current_map = null
var current_seed: int = 0
var players_container = null

func _ready():
	# Start with Main Menu
	_show_main_menu()
	
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	# Listen for connection success to request game state if needed?
	# For now, Server pushes state.

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
			# Trigger redraw on renderer
			map_gen.queue_redraw()
			
	# Add HUD
	if hud_scene:
		var hud = hud_scene.instantiate()
		add_child(hud)

func _on_player_connected(id, info):
	# If we are the server and game is running, sync the new player
	if multiplayer.is_server():
		if current_map:
			# Send map state to new player
			_load_map.rpc_id(id, current_seed)
			# Spawn existing players for new player?
			# MultiplayerSynchronizer handles updates, but we need to spawn nodes.
			# We need a Spawner or manual spawn RPC.
			_spawn_player.rpc(id, info)
			
			# Also spawn ALREADY connected players for the new guy?
			# And spawn the new guy for OTHERS?
			# _spawn_player.rpc() does "call_local", so it spawns on Server + All Clients.
			# But we need to spawn OLD players for the NEW player.
			for pid in NetworkManager.players:
				if pid != id:
					_spawn_player.rpc_id(id, pid, NetworkManager.players[pid])
		else:
			# Game hasn't started, just wait? Or start?
			start_game()
			_spawn_player.rpc(id, info)

@rpc("authority", "call_local", "reliable")
func _spawn_player(id, info):
	print("Spawning player: ", id)
	if not players_container:
		players_container = Node2D.new()
		players_container.name = "Players"
		add_child(players_container)
		
	if players_container.has_node(str(id)):
		return # Already spawned

	var p = player_scene.instantiate()
	p.name = str(id)
	p.player_id = id
	# TODO: Set spawn position based on map safe zone
	p.position = Vector2(100, 100) # Placeholder
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
