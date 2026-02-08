extends Control

const DuckNameGenerator = preload("res://scripts/duck_names.gd")

@onready var name_input = $VBoxContainer/NameInput
@onready var ip_input = $VBoxContainer/IPInput
@onready var host_button = $VBoxContainer/HBoxContainer/HostButton
@onready var join_button = $VBoxContainer/HBoxContainer/JoinButton
@onready var status_label = $StatusLabel


var player_name: String = ""

func _ready():
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	
	# Auto-generate name
	if name_input.text == "":
		name_input.text = DuckNameGenerator.generate_name()

func _on_host_pressed():
	player_name = name_input.text.strip_edges()
	if player_name == "":
		status_label.text = "Please enter a name."
		return
	
	status_label.text = "Starting host..."
	if NetworkManager.host_game(player_name):
		status_label.text = "Hosting! Others can join your IP."
		# _on_connected will be called by NetworkManager
	else:
		status_label.text = "Failed to start host."

func _on_join_pressed():
	player_name = name_input.text.strip_edges()
	if player_name == "":
		status_label.text = "Please enter a name."
		return
	
	var ip = ip_input.text.strip_edges()
	if ip == "":
		ip = "localhost"
	
	status_label.text = "Connecting to " + ip + "..."
	NetworkManager.join_game(ip)

func _on_connected():
	status_label.text = "Connected!"
	
	# If we're a client (not host), register with the server
	if not NetworkManager.is_host:
		NetworkManager.register_player.rpc_id(1, player_name)
	
	# Menu will be cleaned up by GameManager when the map loads

func _on_connection_failed():
	status_label.text = "Connection failed. Check IP and try again."
