extends Node

const SERVER_PORT = 8910
const MAX_PLAYERS = 10

var peer = ENetMultiplayerPeer.new()
var players = {}

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
	
	# Check if we should start as server (headless or command line arg)
	if "--server" in OS.get_cmdline_args() or DisplayServer.get_name() == "headless":
		create_server()

func create_server():
	# Close existing peer if any
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		
	var error = peer.create_server(SERVER_PORT, MAX_PLAYERS)
	if error != OK:
		print("Failed to create server: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Server started on port ", SERVER_PORT)

func join_game(address = "localhost"):
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	var error = peer.create_client(address, SERVER_PORT)
	if error != OK:
		print("Failed to join game: ", error)
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	print("Joining game at ", address)

func _on_player_connected(id):
	print("Player connected: ", id)
	# Registration will happen via RPC

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
	server_disconnected.emit()

@rpc("any_peer", "reliable")
func register_player(name: String):
	var id = multiplayer.get_remote_sender_id()
	players[id] = {"name": name, "id": id}
	player_connected.emit(id, players[id])
	print("Registered player: ", name, " (", id, ")")
