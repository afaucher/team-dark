extends Node

const SERVER_PORT = 8910
const MAX_PLAYERS = 10

var peer = ENetMultiplayerPeer.new()
var players = {}
var is_host = false  # True if we're running as a listen server (host + client)

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal connected_to_server
signal connection_failed
signal server_disconnected

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Check if we should start as dedicated server (headless or command line arg)
	if "--server" in OS.get_cmdline_args() or DisplayServer.get_name() == "headless":
		create_server()

# Dedicated server mode (headless, no local player)
func create_server():
	_close_existing_peer()
	is_host = false
	
	var error = peer.create_server(SERVER_PORT, MAX_PLAYERS)
	if error != OK:
		print("Failed to create server: ", error)
		return false
	multiplayer.multiplayer_peer = peer
	print("Dedicated Server started on port ", SERVER_PORT)
	return true

# Listen server mode (host + local player)
func host_game(player_name: String):
	_close_existing_peer()
	is_host = true
	
	# Create a new peer since the previous may be closed
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(SERVER_PORT, MAX_PLAYERS)
	if error != OK:
		print("Failed to host game: ", error)
		return false
	multiplayer.multiplayer_peer = peer
	print("Listen Server started on port ", SERVER_PORT)
	
	# Register the host as a player immediately (ID 1 is always the server)
	players[1] = {"name": player_name, "id": 1}
	player_connected.emit(1, players[1])
	print("Host registered as player: ", player_name, " (ID 1)")
	
	# Emit connected signal for the host (so menu transitions work)
	connected_to_server.emit()
	return true

func join_game(address = "localhost"):
	_close_existing_peer()
	is_host = false
	
	# Create a new peer
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, SERVER_PORT)
	if error != OK:
		print("Failed to join game: ", error)
		connection_failed.emit()
		return false
	multiplayer.multiplayer_peer = peer
	print("Joining game at ", address)
	return true

func _close_existing_peer():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

func _on_player_connected(id):
	print("Player connected: ", id)
	# Registration happens via RPC from the client

func _on_player_disconnected(id):
	print("Player disconnected: ", id)
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_ok():
	print("Successfully connected to server")
	connected_to_server.emit()

func _on_connected_fail():
	print("Connection failed")
	multiplayer.multiplayer_peer = null
	connection_failed.emit()

func _on_server_disconnected():
	print("Server disconnected")
	multiplayer.multiplayer_peer = null
	players.clear()
	is_host = false
	server_disconnected.emit()

@rpc("any_peer", "reliable")
func register_player(name: String):
	var id = multiplayer.get_remote_sender_id()
	players[id] = {"name": name, "id": id}
	player_connected.emit(id, players[id])
	print("Registered player: ", name, " (", id, ")")
