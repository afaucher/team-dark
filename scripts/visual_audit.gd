extends Node2D

const AutoScreenshot = preload("res://scripts/auto_screenshot.gd")

# Characters
const PlayerScene = preload("res://scenes/characters/player.tscn")
const EasyEnemy = preload("res://scenes/characters/easy_enemy.tscn")
const ScoutEnemy = preload("res://scenes/characters/scout_enemy.tscn")
const HeavyEnemy = preload("res://scenes/characters/heavy_enemy.tscn")
const KamikazeEnemy = preload("res://scenes/characters/kamikaze_enemy.tscn")
const SwarmEnemy = preload("res://scenes/characters/swarm_enemy.tscn")
const MortarEnemy = preload("res://scenes/characters/mortar_enemy.tscn")

# Collections
const MapScene = preload("res://scenes/map/map.tscn")
const HUDScene = preload("res://scenes/ui/hud.tscn")

# Weapons
const PelletGun = preload("res://scenes/weapons/pellet_gun.tscn")
const MachineGun = preload("res://scenes/weapons/machine_gun.tscn")
const Shotgun = preload("res://scenes/weapons/shotgun.tscn")
const GrenadeLauncher = preload("res://scenes/weapons/grenade_launcher.tscn")
const MissileLauncher = preload("res://scenes/weapons/missile_launcher.tscn")

enum AuditMode { GALLERY, WORLD, HUD, FOUR_UP_HUD }

@export var mode: AuditMode = AuditMode.GALLERY

@onready var container = Node2D.new()

func _ready():
	print(">>> [Visual Audit] Mode: ", mode)
	add_child(container)
	
	setup_environment()
	
	match mode:
		AuditMode.GALLERY:
			spawn_gallery()
		AuditMode.WORLD:
			spawn_world()
		AuditMode.HUD:
			spawn_hud()
		AuditMode.FOUR_UP_HUD:
			spawn_four_up_hud()
	
	var screenshotter = AutoScreenshot.new()
	screenshotter.delay_seconds = 3.0 
	screenshotter.prefix = AuditMode.keys()[mode] + "_"
	add_child(screenshotter)

func setup_environment():
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = ThemeManager.bg_void
	
	env.glow_enabled = true
	# Enable levels 2, 4, 6
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 0.0)
	env.set_glow_level(2, 1.0)
	env.set_glow_level(3, 0.0)
	env.set_glow_level(4, 1.0)
	env.set_glow_level(5, 0.0)
	env.set_glow_level(6, 1.0)
	
	env.glow_intensity = ThemeManager.bloom_intensity # 1.2
	env.glow_strength = 1.0
	env.glow_bloom = 0.1
	env.glow_hdr_threshold = ThemeManager.hdr_threshold # 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	var cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	
	if mode == AuditMode.GALLERY:
		cam.zoom = Vector2(0.5, 0.5)
	elif mode == AuditMode.WORLD:
		cam.zoom = Vector2(0.3, 0.3)
	elif mode == AuditMode.HUD:
		cam.zoom = Vector2(1.0, 1.0)

func spawn_gallery():
	# Background Grid
	_add_grid()
	
	var x_spacing = 300
	var y_spacing = 300
	
	# Row 0: Player
	var p = PlayerScene.instantiate()
	p.position = Vector2(0, -y_spacing * 1.5)
	p.set_physics_process(false)
	container.add_child(p)
	
	# Row 1: Basic Tiers
	var enemies = [EasyEnemy, ScoutEnemy, HeavyEnemy]
	for i in range(enemies.size()):
		var e = enemies[i].instantiate()
		e.position = Vector2((i - 1) * x_spacing, -y_spacing * 0.5)
		e.set_physics_process(false)
		container.add_child(e)

	# Row 2: Specialists
	var specialists = [KamikazeEnemy, SwarmEnemy, MortarEnemy]
	for i in range(specialists.size()):
		var s = specialists[i].instantiate()
		s.position = Vector2((i - 1) * x_spacing, y_spacing * 0.5)
		s.set_physics_process(false)
		container.add_child(s)

	# Row 3: Weapons
	var weapons = [PelletGun, MachineGun, Shotgun, GrenadeLauncher, MissileLauncher]
	for i in range(weapons.size()):
		var w = weapons[i].instantiate()
		w.position = Vector2((i - 2) * x_spacing, y_spacing * 1.5)
		if "can_fire" in w: w.can_fire = true
		container.add_child(w)

func spawn_world():
	var map = MapScene.instantiate()
	container.add_child(map)
	var generator = map.get_node("Generator")
	if generator:
		generator.generate_map(12345) # Fixed seed for audit consistency
		map.queue_redraw()

func spawn_hud():
	var hud = HUDScene.instantiate()
	add_child(hud)
	
	# Populate with dummy data
	hud.update_health(0.75)
	hud.update_mount(0, "Pellet Gun", "READY")
	hud.update_mount(1, "Machine Gun", "99%")
	hud.update_mount(2, "Health Kit", "1")
	hud.update_weapon_status(1, true, 0.5)
	hud.update_gems(5, 10)
	
	# Add some off-screen indicators for audit
	var dummy_pickups = Node2D.new()
	add_child(dummy_pickups)
	for i in range(4):
		var d = Node2D.new()
		d.add_to_group("pickups")
		d.set("pickup_type", ["gem", "weapon", "health", "utility"][i])
		d.position = Vector2.RIGHT.rotated(i * PI/2) * 2000 # Way off screen
		dummy_pickups.add_child(d)
	
	# Add a dummy player so HUD can calculate relative positions
	var p = Node2D.new()
	p.add_to_group("players")
	p.position = Vector2.ZERO
	add_child(p)

func _add_grid():
	var grid = Node2D.new()
	grid.set_script(load("res://scripts/hex_grid.gd")) # Use existing grid script if available
	# If hex_grid.gd expects a generator, this might fail. 
	# Let's draw a simple grid manually.
	var grid_draw = Node2D.new()
	grid_draw.set_script(SimpleGridScript)
	container.add_child(grid_draw)

const SimpleGridScript = preload("res://scripts/util/simple_grid.gd")

func spawn_four_up_hud():
	var screen_size = get_viewport().get_visible_rect().size
	var half_size = screen_size / 2.0
	
	var styles = [
		ThemeManager.HUDStyle.SEGMENTED,
		ThemeManager.HUDStyle.MINIMALIST,
		ThemeManager.HUDStyle.TACTICAL,
		ThemeManager.HUDStyle.COMBAT
	]
	
	var titles = ["SEGMENTED (ART 2)", "MINIMALIST (ART 3)", "TACTICAL", "AGGRESSIVE"]
	
	for i in range(4):
		var hud_instance = HUDScene.instantiate()
		var ctrl = hud_instance.get_node("Control")
		hud_instance.remove_child(ctrl)
		hud_instance.queue_free()
		
		container.add_child(ctrl)
		ctrl.scale = Vector2(0.5, 0.5)
		ctrl.position = Vector2((i % 2) * half_size.x, floor(i / 2) * half_size.y)
		
		# Now that ctrl has the script, we can call its methods
		ctrl.forced_style = styles[i]
		ctrl.update_health(0.65)
		ctrl.update_mount(0, "Pellet Gun", "READY")
		ctrl.update_mount(1, "Machine Gun", "50%")
		ctrl.update_gems(i + 1, 10)
		
		# Add a title label
		var l = Label.new()
		l.text = titles[i]
		l.position = Vector2(100, 100)
		l.add_theme_font_size_override("font_size", 60)
		l.modulate = ThemeManager.player_primary
		ctrl.add_child(l)
		# ... etc
		
		# Add a background panel for each quad
		var bg = ColorRect.new()
		bg.color = Color(1, 1, 1, 0.05)
		bg.size = half_size
		bg.show_behind_parent = true
		ctrl.add_child(bg)
