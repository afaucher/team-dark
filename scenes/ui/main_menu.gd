extends Control

const DuckNameGenerator = preload("res://scripts/duck_names.gd")

@onready var name_input = $VBoxContainer/NameInput
@onready var join_button = $VBoxContainer/JoinButton
@onready var status_label = $StatusLabel

func _ready():
	join_button.pressed.connect(_on_join_pressed)
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	
	# Auto-generate name
	if name_input.text == "":
		name_input.text = DuckNameGenerator.generate_name()

func _on_join_pressed():
	var player_name = name_input.text
	if player_name.strip_edges() == "":
		status_label.text = "Please enter a name."
		return
	
	status_label.text = "Connecting..."
	NetworkManager.join_game() # Default to localhost for now
	# In a real game, you might want IP input

func _on_connected():
	status_label.text = "Connected!"
	NetworkManager.register_player.rpc_id(1, name_input.text)
	# Transition to game scene is handled by NetworkManager or GameManager
	# queue_free() or hide()

func _on_connection_failed():
	status_label.text = "Connection failed."
