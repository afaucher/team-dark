extends CanvasLayer

@onready var health_bar = $Control/HealthBar
@onready var mounts_container = $Control/Mounts
@onready var mount_left_label = $Control/Mounts/Left/Label
@onready var mount_right_label = $Control/Mounts/Right/Label
@onready var mount_top_label = $Control/Mounts/Top/Label
@onready var teammate_list = $Control/TeammateList

func update_health(ratio: float):
	health_bar.value = ratio * 100

func update_mount(mount_idx: int, item_name: String, status: String):
	var label
	match mount_idx:
		0: label = mount_left_label
		1: label = mount_right_label
		2: label = mount_top_label
	
	if label:
		label.text = item_name + "\n" + status

func update_teammates(players: Dictionary):
	# Clear list
	for child in teammate_list.get_children():
		child.queue_free()
	
	for id in players:
		var p = players[id]
		var label = Label.new()
		label.text = p.name
		teammate_list.add_child(label)
