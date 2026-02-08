extends Control

@onready var lobby_list = $Panel/VBoxContainer/LobbyList
@onready var status_label = $Panel/VBoxContainer/StatusLabel

func _ready():
	SteamManager.lobby_match_list.connect(_on_lobbies_found)
	SteamManager.lobby_joined.connect(_on_lobby_joined)
	SteamManager.lobby_created.connect(_on_lobby_created)
	
	if SteamManager.steam_id == 0:
		status_label.text = "Steam not initialized! (Check if Steam is running)"
		$Panel/VBoxContainer/HBoxContainer/HostButton.disabled = true
		$Panel/VBoxContainer/HBoxContainer/RefreshButton.disabled = true
	else:
		status_label.text = "Connected to Steam: " + SteamManager.steam_username

func _on_host_button_pressed():
	if SteamManager.steam_id == 0: return
	status_label.text = "Creating Lobby..."
	SteamManager.create_lobby()

func _on_lobby_created(connect: int, id: int):
	if connect == 1:
		status_label.text = "Lobby Created! Waiting for transition..."
	else:
		status_label.text = "Failed to create lobby: " + str(connect)

func _on_refresh_button_pressed():
	if SteamManager.steam_id == 0: return
	status_label.text = "Searching for Lobbies..."
	lobby_list.clear()
	SteamManager.list_lobbies()

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

func _on_lobbies_found(lobbies):
	lobby_list.clear()
	status_label.text = "Found " + str(lobbies.size()) + " lobbies"
	
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var member_count = Steam.getNumLobbyMembers(lobby)
		
		# "Lobby Name (X/4)"
		var title = str(lobby_name) + " (" + str(member_count) + "/4)"
		lobby_list.add_item(title)
		# Store lobby ID as metadata for the item we just added
		lobby_list.set_item_metadata(lobby_list.get_item_count() - 1, lobby)

func _on_lobby_list_item_activated(index):
	var lobby_id = lobby_list.get_item_metadata(index)
	status_label.text = "Joining Lobby " + str(lobby_id) + "..."
	SteamManager.join_lobby(lobby_id)

func _on_lobby_joined(lobby_id, _steam_id):
	status_label.text = "Joined! Starting game..."
	# Transition to the game scene
	# We give it a tiny bit of time for Steam to settle
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/game.tscn")
