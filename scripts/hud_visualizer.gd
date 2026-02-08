extends Node

const HUDScene = preload("res://scenes/ui/hud.tscn")

var hud_instance
var time_accum = 0.0

func _ready():
	print("Starting HUD Visualizer...")
	
	# Instantiate HUD
	hud_instance = HUDScene.instantiate()
	add_child(hud_instance)
	
	# Setup initial state
	hud_instance.update_health(1.0)
	hud_instance.update_mount(0, "Pellet Gun", "Ready")
	hud_instance.update_mount(1, "Empty", "-")
	hud_instance.update_mount(2, "Empty", "-")
	
	# Add some dummy teammates
	var dummy_players = {
		1: {"name": "PlayerOne"},
		2: {"name": "Teammate_A"},
		3: {"name": "Teammate_B"}
	}
	hud_instance.update_teammates(dummy_players)

func _process(delta):
	time_accum += delta
	
	# Simulate Health fluctuation
	var health_ratio = (sin(time_accum * 2.0) + 1.0) / 2.0
	hud_instance.update_health(health_ratio)
	
	# Simulate Mount Status updates every 2 seconds
	if int(time_accum * 10) % 20 == 0:
		_randomize_mounts()

func _randomize_mounts():
	var weapons = ["Pellet Gun", "Machine Gun", "Shotgun", "Sniper"]
	var statuses = ["Ready", "Reloading...", "Empty", "Overheated"]
	
	for i in range(3):
		var w = weapons[randi() % weapons.size()]
		var s = statuses[randi() % statuses.size()]
		hud_instance.update_mount(i, w, s)
