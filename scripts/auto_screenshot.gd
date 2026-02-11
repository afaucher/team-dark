extends Node

@export var delay_seconds: float = 1.0
@export var output_path: String = "user://screenshots"

@export var prefix: String = ""

func _ready():
	await get_tree().create_timer(delay_seconds).timeout
	take_screenshot()
	get_tree().quit()

func take_screenshot():
	var image = get_viewport().get_texture().get_image()
	var time = Time.get_datetime_dict_from_system()
	var filename = "%scapture_%02d_%02d_%02d_%02d_%02d_%02d.png" % [prefix, time.year, time.month, time.day, time.hour, time.minute, time.second]
	
	# Ensure directory exists (Godot user://)
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
	
	var full_path = "user://screenshots/" + filename
	# If we want to save to the project folder for easy access from host OS without digging into AppData:
	# Res:// is read-only in exported builds, but in editor/debug it might be writable, but usually we use user://.
	# However, for this testing tool, we want to see the result easily.
	# Let's try to save to "res://screenshots" if valid, or a global path if possible. 
	# Godot sandboxing might restrict this. 
	# For local development tool, we can use ProjectSettings.globalize_path("res://")
	
	var global_path = ProjectSettings.globalize_path("res://docs/screenshots/")
	var native_dir = DirAccess.open(global_path)
	if not native_dir:
		var d = DirAccess.open("res://")
		if not d.dir_exists("docs/screenshots"):
			d.make_dir("docs/screenshots")  # This might fail if docs doesn't exist, but docs usually exists.
			# If docs doesn't exist, we might need to make it.
			if not d.dir_exists("docs"):
				d.make_dir("docs")
			if not d.dir_exists("docs/screenshots"):
				d.make_dir("docs/screenshots")
				
		global_path = ProjectSettings.globalize_path("res://docs/screenshots/")
	
	var final_path = global_path + filename
	image.save_png(final_path)
	print("Screenshot saved to: " + final_path)
