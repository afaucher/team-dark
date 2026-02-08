extends Control

func _on_play_button_pressed():
	# For now, just load the server browser
	get_tree().change_scene_to_file("res://scenes/menus/server_browser.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
