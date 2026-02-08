extends Node

var show_debug: bool = false

func _input(event):
	if event.is_action_pressed("toggle_debug"):
		show_debug = not show_debug
		print("Debug visualization: ", "ON" if show_debug else "OFF")
