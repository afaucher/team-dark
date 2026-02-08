extends Node

# SteamManager.gd - Autoload for handling Steamworks integration

signal lobby_created(connect_code, lobby_id)
signal lobby_joined(lobby_id, steam_id)
signal lobby_match_list(lobbies)

var is_on_steam_deck: bool = false
var is_online: bool = false
var is_owned: bool = false
var steam_app_id: int = 480
var steam_id: int = 0
var steam_username: String = ""

# Lobby data
var lobby_data = []
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_max_members: int = 4
var lobby_vote_kick: bool = false

func _ready() -> void:
	_initialize_steam()

func _initialize_steam() -> void:
	var init: Dictionary = Steam.steamInit()
	print("[Steam] Status: " + str(init))

	if init['status'] != 1:
		print("[Steam] Failed to initialize: " + str(init['verbal']))
		# Don't quit in editor, just warn
		if not OS.has_feature("editor"):
			get_tree().quit()
		return

	is_online = Steam.loggedOn()
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()

	print("[Steam] User: " + steam_username + " (ID: " + str(steam_id) + ")")
	
	# Connect signals
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.join_requested.connect(_on_join_requested)
	
	_check_command_line()

func _process(_delta: float) -> void:
	Steam.run_callbacks()

func _check_command_line() -> void:
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg == "+connect_lobby":
			# Handle command line join
			pass

# --- Lobby Functions ---

func create_lobby() -> void:
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_max_members)

func list_lobbies() -> void:
	print("[Steam] Requesting lobby list...")
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListStringFilter("game", "team_dark", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func join_lobby(id: int) -> void:
	print("[Steam] Joining lobby: " + str(id))
	Steam.joinLobby(id)

func leave_lobby() -> void:
	if lobby_id != 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
		lobby_members.clear()
		# Close P2P session

# --- Callbacks ---

func _on_lobby_created(connect: int, id: int) -> void:
	if connect == 1:
		lobby_id = id
		print("[Steam] Created Lobby: " + str(lobby_id))
		
		# Set lobby data
		Steam.setLobbyData(lobby_id, "name", str(steam_username) + "'s Lobby")
		Steam.setLobbyData(lobby_id, "game", "team_dark")
		
		allow_p2p()
		emit_signal("lobby_created", connect, id)
	else:
		print("[Steam] Failed to create lobby: " + str(connect))

func _on_lobby_match_list(lobbies: Array) -> void:
	print("[Steam] Found " + str(lobbies.size()) + " lobbies")
	lobby_data = lobbies
	emit_signal("lobby_match_list", lobbies)

func _on_lobby_joined(id: int, permissions: int, locked: bool, response: int) -> void:
	if response == 1:
		lobby_id = id
		print("[Steam] Joined Lobby: " + str(lobby_id))
		emit_signal("lobby_joined", id, steam_id)
	else:
		print("[Steam] Failed to join lobby: " + str(response))

func _on_lobby_chat_update(id: int, changed_id: int, making_change_id: int, chat_state: int) -> void:
	# Handle user join/leave
	match chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			print("[Steam] User joined: " + str(changed_id))
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
			print("[Steam] User left: " + str(changed_id))
		Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
			print("[Steam] User disconnected: " + str(changed_id))

func _on_join_requested(id: int, friend_id: int) -> void:
	join_lobby(id)

func allow_p2p() -> void:
	# Configure MultiplayerPeer in Godot 4
	pass
