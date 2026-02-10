extends Control

func _ready():
	var args = OS.get_cmdline_args()
	var file = FileAccess.open("user://last_cli_args.txt", FileAccess.WRITE)
	if file:
		file.store_string(str(args))
		file.close()

	for arg in args:
		# Check for direct flag OR nested args from godot-rl
		if "--training" in arg or "--speedup" in arg or "--port" in arg:
			# Use call_deferred to safely switch scenes during _ready/input
			get_tree().call_deferred("change_scene_to_file", "res://scenes/training/training_manager.tscn")
			return

func _on_play_button_pressed():
	# For now, just load the server browser
	get_tree().change_scene_to_file("res://scenes/menus/server_browser.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
