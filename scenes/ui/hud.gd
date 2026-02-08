extends CanvasLayer

@onready var health_bar = $Control/HealthBar
@onready var mounts_container = $Control/Mounts
@onready var mount_left = $Control/Mounts/Left
@onready var mount_right = $Control/Mounts/Right
@onready var mount_top = $Control/Mounts/Top
@onready var mount_left_label = $Control/Mounts/Left/Label
@onready var mount_right_label = $Control/Mounts/Right/Label
@onready var mount_top_label = $Control/Mounts/Top/Label
@onready var mount_left_icon_container = $Control/Mounts/Left/Icon
@onready var mount_right_icon_container = $Control/Mounts/Right/Icon
@onready var mount_top_icon_container = $Control/Mounts/Top/Icon
@onready var teammate_list = $Control/TeammateList
@onready var fps_label = $Control/FPSCounter

const WeaponIconScript = preload("res://scripts/ui/weapon_icon.gd")

const PANEL_STYLE = preload("res://resources/ui/hud_panel_style.tres")
const HEALTH_FILL = preload("res://resources/ui/health_fill_style.tres")
const HEALTH_BG = preload("res://resources/ui/health_bg_style.tres")

func _process(_delta):
	if fps_label:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

func _ready():
	# Apply Styles
	mount_left.add_theme_stylebox_override("panel", PANEL_STYLE)
	mount_right.add_theme_stylebox_override("panel", PANEL_STYLE)
	mount_top.add_theme_stylebox_override("panel", PANEL_STYLE)
	
	health_bar.add_theme_stylebox_override("bg", HEALTH_BG)
	health_bar.add_theme_stylebox_override("fill", HEALTH_FILL)


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
				_:
					icon.type = 0 # NONE

func update_teammates(players: Dictionary):
	# Clear list
	for child in teammate_list.get_children():
		child.queue_free()
	
	for id in players:
		var p = players[id]
		var label = Label.new()
		label.text = p.name
		teammate_list.add_child(label)
