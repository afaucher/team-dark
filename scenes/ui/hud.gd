extends Control

var forced_style = -1 # -1 means use ThemeManager

@onready var health_bar = $HealthBar
@onready var mounts_container = $Mounts
@onready var mount_left = $Mounts/Left
@onready var mount_right = $Mounts/Right
@onready var mount_top = $Mounts/Top
@onready var mount_left_label = $Mounts/Left/Label
@onready var mount_right_label = $Mounts/Right/Label
@onready var mount_top_label = $Mounts/Top/Label
@onready var mount_left_icon_container = $Mounts/Left/Icon
@onready var mount_right_icon_container = $Mounts/Right/Icon
@onready var mount_top_icon_container = $Mounts/Top/Icon
@onready var teammate_list = $TeammateList
@onready var fps_label = $FPSCounter
@onready var gem_label = $GemCounter

const WeaponIconScript = preload("res://scripts/ui/weapon_icon.gd")

const PANEL_STYLE = preload("res://resources/ui/hud_panel_style.tres")
const HEALTH_FILL = preload("res://resources/ui/health_fill_style.tres")
const HEALTH_BG = preload("res://resources/ui/health_bg_style.tres")

func _process(_delta):
	if fps_label:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	
	# Request redraw for indicators
	queue_redraw()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep HUD alive during RL training pauses
	# Connect _draw to self
	draw.connect(_on_control_draw)
	
	# Initial style setup
	_update_hud_styles()

func _update_hud_styles():
	var style = ThemeManager.current_hud_style
	match style:
		ThemeManager.HUDStyle.SEGMENTED:
			health_bar.show_percentage = false
		ThemeManager.HUDStyle.MINIMALIST:
			health_bar.show_percentage = false
		ThemeManager.HUDStyle.TACTICAL:
			health_bar.show_percentage = true

func _on_control_draw():
	_draw_styled_elements()
	
	# Draw off-screen indicators for pickups
	var players = get_tree().get_nodes_in_group("players")
	if players.size() == 0: return

func _draw_styled_elements():
	var style = ThemeManager.current_hud_style
	if forced_style != -1:
		style = forced_style
	var primary = ThemeManager.player_primary
	
	# Draw Health Bar Background / Frame
	var hb_rect = health_bar.get_global_rect()
	hb_rect.position -= Vector2(5, 5)
	hb_rect.size += Vector2(10, 10)
	
	match style:
		ThemeManager.HUDStyle.SEGMENTED:
			draw_rect(hb_rect, Color.BLACK, true)
			draw_rect(hb_rect, primary, false, 3.0)
			# Add segments markers
			for i in range(1, 10):
				var x = hb_rect.position.x + (hb_rect.size.x * i / 10.0)
				draw_line(Vector2(x, hb_rect.position.y), Vector2(x, hb_rect.end.y), primary * 0.5, 1.0)
		
		ThemeManager.HUDStyle.MINIMALIST:
			_draw_rounded_rect(hb_rect, primary, 1.0, 8.0)
			
		ThemeManager.HUDStyle.TACTICAL:
			# Angled frame
			var pts = [
				hb_rect.position,
				Vector2(hb_rect.end.x - 20, hb_rect.position.y),
				hb_rect.end,
				Vector2(hb_rect.position.x + 20, hb_rect.end.y)
			]
			draw_colored_polygon(pts, Color.BLACK)
			draw_polyline(pts, primary, 2.0)

func _draw_rounded_rect(rect: Rect2, color: Color, width: float, radius: float):
	# Simple approximation using polyline
	var pts = []
	var res = 8
	for i in range(res + 1):
		var ang = PI + float(i) / res * PI/2
		pts.append(rect.position + Vector2(radius, radius) + Vector2(cos(ang), sin(ang)) * radius)
	# ... etc (implementing full rounded rect is verbose, I'll use a helper or simpler version)
	draw_rect(rect, color, false, width) # Fallback for now


func update_health(ratio: float):
	health_bar.value = ratio * 100

func update_mount(mount_idx: int, item_name: String, status: String):
	var label
	var container
	match mount_idx:
		0: 
			label = mount_left_label
			container = mount_left_icon_container
		1: 
			label = mount_right_label
			container = mount_right_icon_container
		2: 
			label = mount_top_label
			container = mount_top_icon_container
	
	if label:
		label.text = status # Reduced text, name is shown by icon
	
	if container:
		# Sync Icon
		var icon = container.get_node_or_null("WeaponIcon")
		if not icon:
			icon = Control.new()
			icon.set_script(WeaponIconScript)
			icon.name = "WeaponIcon"
			container.add_child(icon)
		
		if item_name == "Empty":
			icon.visible = false
			icon.type = 0 # NONE
		else:
			icon.visible = true
			match item_name.to_lower():
				"pellet gun":
					icon.type = 1 # PELLET_GUN
				"machine gun":
					icon.type = 2 # MACHINE_GUN
				"shotgun":
					icon.type = 3 # SHOTGUN
				"grenade launcher":
					icon.type = 4 # GRENADE_LAUNCHER
				"missile launcher":
					icon.type = 5 # MISSILE_LAUNCHER
				"health kit":
					icon.type = 6 # HEALTH_KIT
				_:
					icon.type = 0 # NONE

func update_weapon_status(mount_idx: int, is_ready: bool, ammo_ratio: float):
	var container
	match mount_idx:
		0: container = mount_left_icon_container
		1: container = mount_right_icon_container
		2: container = mount_top_icon_container
	
	if container:
		var icon = container.get_node_or_null("WeaponIcon")
		if icon:
			icon.is_ready = is_ready
			icon.ammo_ratio = ammo_ratio

func update_teammates(players: Dictionary):
	# Clear list
	for child in teammate_list.get_children():
		child.queue_free()
	
	for id in players:
		var p = players[id]
		var label = Label.new()
		label.text = p.name

func update_gems(count: int, max_gems: int):
	gem_label.text = "Gems: " + str(count) + " / " + str(max_gems)
	if count >= max_gems:
		gem_label.modulate = Color(0, 1, 0) # Green
	else:
		gem_label.modulate = Color(1, 0, 1) # Magenta

	var players = get_tree().get_nodes_in_group("players")
	if players.size() == 0: return
	var player = players[0]

	var camera = get_viewport().get_camera_2d()
	if not camera: return

	var screen_size = get_viewport().get_visible_rect().size
	var margin = 40.0
	
	var pickups = get_tree().get_nodes_in_group("pickups")
	var counts = {"gem": 0, "weapon": 0, "health": 0, "utility": 0, "ammo": 0, "unknown": 0}
	
	for pickup in pickups:
		if not is_instance_valid(pickup) or not pickup.is_inside_tree(): continue
		
		var type = "unknown"
		if "pickup_type" in pickup:
			type = pickup.pickup_type
		
		if counts.has(type): counts[type] += 1
		else: counts["unknown"] += 1

		# Get screen position
		var canvas_transform = get_viewport().get_canvas_transform()
		var screen_pos = canvas_transform * pickup.global_position
		
		if screen_pos.x < 0 or screen_pos.x > screen_size.x or \
		   screen_pos.y < 0 or screen_pos.y > screen_size.y:
			# OFF SCREEN - Draw Edge Dot
			var indicator_pos = Vector2()
			indicator_pos.x = clamp(screen_pos.x, margin, screen_size.x - margin)
			indicator_pos.y = clamp(screen_pos.y, margin, screen_size.y - margin)
			
			# Indicator color
			var color = Color(1, 1, 1) # Default
			var dot_size = 5.0
			match type:
				"gem": 
					color = Color(1, 0, 1)
					dot_size = 7.0 # Make gems larger
				"weapon": color = Color(0, 1, 1)
				"utility": color = Color(0.5, 0, 1) # Purple for utilities
				"health": color = Color(1, 0, 0)
				"ammo": color = Color(1, 1, 0)
			
			# Draw indicator with a small drop shadow
			draw_circle(indicator_pos + Vector2(2,2), dot_size + 1.0, Color(0,0,0, 0.5))
			draw_circle(indicator_pos, dot_size, color)
	
	# --- EXTRACTION INDICATOR ---
	var game_manager = get_tree().current_scene
	if game_manager and "collected_gems" in game_manager:
		if game_manager.collected_gems >= game_manager.MAX_GEMS:
			var extraction = get_tree().current_scene.find_child("ExtractionPoint", true, false)
			if extraction and is_instance_valid(extraction):
				var canvas_transform = get_viewport().get_canvas_transform()
				var screen_pos = canvas_transform * extraction.global_position
				
				if screen_pos.x < 0 or screen_pos.x > screen_size.x or \
				   screen_pos.y < 0 or screen_pos.y > screen_size.y:
					var indicator_pos = Vector2()
					indicator_pos.x = clamp(screen_pos.x, margin, screen_size.x - margin)
					indicator_pos.y = clamp(screen_pos.y, margin, screen_size.y - margin)
					
					# Draw a distinct Green Hex or Triangle for Exit
					var pts = []
					var sides = 6
					var size = 12.0
					for i in range(sides):
						var angle = i * TAU / sides
						pts.append(indicator_pos + Vector2(cos(angle), sin(angle)) * size)
					
					draw_colored_polygon(pts, Color.GREEN)
					draw_polyline(pts, Color.WHITE, 2.0)
	
