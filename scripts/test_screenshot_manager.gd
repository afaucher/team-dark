extends Node

const MapScene = preload("res://scenes/map/map.tscn")
const AutoScreenshot = preload("res://scripts/auto_screenshot.gd")

func _ready():
	print("Starting Visual Test...")
	
	# Instantiate Map
	var map_instance = MapScene.instantiate()
	add_child(map_instance)
	
	# Generate Map
	# Map scene structure: Root (MapRenderer) -> Generator
	var generator = map_instance.get_node("Generator")
	if generator:
		var seed_val = randi()
		print("Generating map with seed: ", seed_val)
		generator.generate_map(seed_val)
		map_instance.queue_redraw()
	
	# Add Screenshotter
	var screenshotter = AutoScreenshot.new()
	screenshotter.delay_seconds = 1.0 # Wait for redraw
	screenshotter.output_path = "user://screenshots"
	add_child(screenshotter)
	
	# Add Camera2D
	var camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	camera.zoom = Vector2(0.5, 0.5) # Zoom out to see more
	print("Camera2D added and active")
