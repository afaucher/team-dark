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
var hud_instance = null

const MAX_GEMS: int = 3
var collected_gems: int = 0

var pathfinder = null

func _ready():
	add_to_group("managers")
	
	# Setup Pathfinding
	pathfinder = Node.new()
	pathfinder.name = "Pathfinding"
	pathfinder.set_script(load("res://scripts/training/pathfinding_manager.gd"))
	add_child(pathfinder)
	# Configure Projectile Spawner
	var spawner = get_node_or_null("ProjectileSpawner")
	if spawner:
		spawner.add_spawnable_scene("res://scenes/projectiles/pellet.tscn")
	
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	
	# Start check: If we came from the Steam Server Browser, a peer is already active.
	if multiplayer.multiplayer_peer and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		_setup_steam_session()
	else:
		# Check for CLI join address (e.g., "localhost")
		var args = OS.get_cmdline_args()
		var join_target = ""
		for arg in args:
			if arg == "localhost" or arg.find(".") > -1:
				join_target = arg
				break
		
		if join_target != "":
			print("[Game] CLI Join detected: ", join_target)
			NetworkManager.join_game(join_target)
			# Hide menu nodes if they exist
			for child in get_children():
				if child is Control: child.visible = false
		elif multiplayer.is_server():
			# Dedicated server - auto-start the game
			print("[Game] Dedicated server detected, auto-starting game...")
			await get_tree().process_frame
			start_game()
		else:
			_show_main_menu()

func _setup_steam_session():
	print("[Game] Steam session detected, skipping internal menu.")
	var my_name = SteamManager.steam_username
	if my_name == "": my_name = "Player " + str(multiplayer.get_unique_id())
	
	NetworkManager.is_host = multiplayer.is_server()
	# Register self locally
	NetworkManager.players[multiplayer.get_unique_id()] = {"name": my_name, "id": multiplayer.get_unique_id()}
	NetworkManager.player_connected.emit(multiplayer.get_unique_id(), NetworkManager.players[multiplayer.get_unique_id()])
	
	if NetworkManager.is_host:
		print("[Game] Steam Host starting game...")
		# Wait a frame to ensure all nodes are ready
		await get_tree().process_frame
		start_game()
	else:
		print("[Game] Steam Client registering with host...")
		# Clients need to tell the server their name
		NetworkManager.register_player.rpc_id(1, my_name)

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
		players_container.z_index = 10
		add_child(players_container)

@rpc("authority", "call_local", "reliable")
func _load_map(seed_val: int):
	print("Loading map with seed: ", seed_val)
	current_seed = seed_val
	
	# Cleanup menu and HUD
	if hud_instance:
		hud_instance.queue_free()
		hud_instance = null
		
	for child in get_children():
		if child is Control: # Assuming Menu are Controls
			child.queue_free()
	
	# Instantiate Map
	if map_generator_scene:
		var map_gen = map_generator_scene.instantiate()
		add_child(map_gen)
		move_child(map_gen, 0) # Place at the very bottom of the tree
		if map_gen is Node2D:
			map_gen.z_index = -10 # Ensure it's visually below everything
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
			if pickup_spawner_scene:
				var p_spawner = pickup_spawner_scene.instantiate()
				add_child(p_spawner)
				if p_spawner.has_method("spawn_pickups"):
					if multiplayer.is_server(): # Only server calls the spawn method
						p_spawner.spawn_pickups(internal_gen.hex_map)
				
			if enemy_spawner_scene:
				var e_spawner = enemy_spawner_scene.instantiate()
				add_child(e_spawner)
				
				# Update pathfinding graph before spawning
				if pathfinder and pathfinder.has_method("update_graph"):
					pathfinder.update_graph(internal_gen.hex_map)
				
				if e_spawner.has_method("spawn_enemies"):
					if multiplayer.is_server(): # Only server calls the spawn method
						e_spawner.spawn_enemies(internal_gen.hex_map)
			
	# Add HUD
	if hud_scene:
		hud_instance = hud_scene.instantiate()
		add_child(hud_instance)

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
	print("[Game] _spawn_player called for ID: ", id, " at ", spawn_pos)
	if not players_container:
		players_container = Node2D.new()
		players_container.name = "Players"
		players_container.z_index = 10
		add_child(players_container)
		
	if players_container.has_node(str(id)):
		print("[Game] Player ", id, " already exists, skipping spawn.")
		return

	var p = player_scene.instantiate()
	p.name = str(id)
	p.player_id = id
	p.position = spawn_pos
	
	# Check for autoplay flag
	if OS.get_cmdline_args().has("--autoplay"):
		p.ai_mode = 1 # HARDCODED
		print("Autoplay enabled for Player ", id)
		
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

@rpc("any_peer", "call_local", "reliable")
func increment_gem_count():
	if not multiplayer.is_server(): return
	
	if collected_gems >= MAX_GEMS:
		return
		
	collected_gems += 1
	_sync_gem_count.rpc(collected_gems)
	
	if collected_gems >= MAX_GEMS:
		print("ALL GEMS COLLECTED! Extraction Point Active!")
		var extraction = get_tree().current_scene.find_child("ExtractionPoint", true, false)
		if extraction and extraction.has_method("activate"):
			extraction.activate.rpc()

@rpc("authority", "call_local", "reliable")
func _sync_gem_count(count: int):
	# On client, update the variable and UI
	collected_gems = count
	print("Gems Collected: ", count, "/", MAX_GEMS)
	
	if hud_instance and hud_instance.has_method("update_gems"):
		hud_instance.update_gems(collected_gems, MAX_GEMS)
	
@rpc("authority", "call_local", "reliable")
func trigger_win(player_id: int):
	# Could be authority or any peer notifying?
	# For security, only server should call this RPC on clients.
	# But server logic handles the call from object.
	
	print("WIN CONDITION MET by Player ", player_id)
	
	# Show Win Screen / Menu
	if hud_instance:
		var label = Label.new()
		label.text = "VICTORY!\nPlayer " + str(player_id) + " Extracted!"
		label.add_theme_font_size_override("font_size", 64)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_CENTER)
		hud_instance.add_child(label)
	
	# After delay, restart?
	await get_tree().create_timer(5.0).timeout
	# If server, restart game? This is simple logic for now.
	if multiplayer.is_server():
		# _load_map again? Or return to lobby?
		pass

func on_player_died(player_id: int):
	# Server only
	if not multiplayer.is_server(): return
	
	print("GameManager: Player ", player_id, " died. Respawning in 3s...")
	# 3 second respawn timer
	await get_tree().create_timer(3.0).timeout
	_respawn_player_logic(player_id)

func _respawn_player_logic(player_id: int):
	var spawn_pos = Vector2(0, 0) # Default start
	
	# Find teammate to spawn on
	var teammates_alive = []
	if players_container:
		for p in players_container.get_children():
			# Check if alive (property check) and NOT the dying player
			if p.player_id != player_id:
				if "is_dead" in p and not p.is_dead:
					teammates_alive.append(p)
	
	if teammates_alive.size() > 0:
		var target = teammates_alive.pick_random()
		# Spawn nearby (offset)
		var offset = Vector2.from_angle(randf() * TAU) * 100.0
		spawn_pos = target.global_position + offset
		print("Respawning Player ", player_id, " near Teammate ", target.player_id)
	else:
		print("Respawning Player ", player_id, " at Start (No teammates alive)")
		# Try to find a safe spot near 0,0 or map center if 0,0 isn't safe? 
		# For now, 0,0 is safe-ish or just the start pad.
	
	# Call respawn on the player object
	if players_container and players_container.has_node(str(player_id)):
		var p = players_container.get_node(str(player_id))
		p.respawn.rpc(spawn_pos)
