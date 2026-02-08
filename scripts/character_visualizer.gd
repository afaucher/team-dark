extends Node2D

const PlayerScene = preload("res://scenes/characters/player.tscn")
# Assuming Enemy scene exists, if not we will skip or use placeholder
# The user mentioned "any enemy types available". I saw "enemy.tscn" in the file list.
const EnemyScene = preload("res://scenes/characters/enemy.tscn")

@onready var container = $Container
@onready var label = $CanvasLayer/Label

var characters = []

func _ready():
	print("Starting Character Visualizer...")
	
	# Setup Environment (Neon Glow)
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1a1a2e") # Dark background
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_strength = 1.0
	env.glow_mix = 0.5 # Additive
	env.glow_bloom = 0.5
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	_spawn_characters()
	
func _spawn_characters():
	# Spawn Player
	var player = PlayerScene.instantiate()
	player.position = Vector2(0, 0)
	player.name = "PlayerViz"
	player.set_physics_process(false) # Disable game logic/movement
	container.add_child(player)
	characters.append(player)
	
	# Spawn Enemies (Tiers)
	if EnemyScene:
		var tiers = [
			{"color": Color("#ff9a00"), "pos": Vector2(-150, -100), "name": "Enemy_T1"}, # Orange
			{"color": Color("#b829ea"), "pos": Vector2(0, -150), "name": "Enemy_T2"},    # Purple
			{"color": Color("#39ff14"), "pos": Vector2(150, -100), "name": "Enemy_T3"}    # Green
		]
		
		for tier in tiers:
			var enemy = EnemyScene.instantiate()
			enemy.position = tier.pos
			enemy.color_theme = tier.color
			enemy.name = tier.name
			enemy.set_physics_process(false) # Disable AI movement
			container.add_child(enemy)
			characters.append(enemy)

	label.text = "Visualizer Mode\nCharacters: " + str(characters.size()) + "\n(Player + 3 Enemy Tiers)"

func _process(delta):
	var time = Time.get_ticks_msec() / 1000.0
	
	for char_node in characters:
		# Rotate
		char_node.rotation += delta * 1.0
		
		# Bobbing animation
		char_node.position.y += sin(time * 2.0 + char_node.get_instance_id()) * 0.5
		
		# Pulse scale
		var scale_pulse = 1.0 + sin(time * 5.0) * 0.05
		char_node.scale = Vector2(scale_pulse, scale_pulse)
		
		# Simulate Firing/Action (Visual flash override?)
		# Since we don't have sprites yet, we just manipulate transform.
