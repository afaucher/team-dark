extends Area2D

class_name Pickup

@export var pickup_name: String = "Generic Pickup"
@export var pickup_type: String = "weapon" # weapon, health, ammo, gem
@export var item_scene: PackedScene # The weapon scene to equip
@export var item_scene_path: String = "" # Path for network sync

var radius: float = 24.0
var color: Color = Color.WHITE

func _ready():
	collision_layer = 16 # Layer 5: Pickup
	
	# Ensure it has a collision shape
	if get_child_count() == 0:
		var collision = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = radius + 10.0
		collision.shape = circle
		add_child(collision)
	
	add_to_group("pickups")
	
	# Add gems to a separate group so AI can find them easily
	if pickup_type == "gem":
		add_to_group("gems")
	
	# print("[Pickup] Spawned: ", pickup_name, " type: ", pickup_type, " at ", global_position)
	
	if item_scene_path != "" and item_scene == null:
		item_scene = load(item_scene_path)
	
	_update_color()
	queue_redraw()

func _update_color():
	match pickup_type:
		"weapon": color = Color(0, 1, 1) # Cyan
		"health": color = Color(1, 0, 0) # Red
		"ammo": color = Color(1, 1, 0) # Yellow
		"gem": color = Color(1, 0, 1) # Magenta
		"utility": color = Color(1, 0.5, 0) # Orange

func _draw():
	# Vector Art Style Pickup
	var inner_radius = radius * 0.6
	var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.1
	var current_radius = radius * pulse
	
	# Glow backing
	draw_circle(Vector2.ZERO, current_radius + 6, color * Color(1, 1, 1, 0.2))
	
	# Outer Ring
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 32, color, 4.0, true)
	
	# Inner Fill (Black center)
	draw_circle(Vector2.ZERO, radius * 0.5, Color.BLACK)
	
	# Type Icon
	var icon_color = color
	match pickup_type:
		"weapon":
			draw_rect(Rect2(-8, -3, 16, 6), icon_color)
			draw_rect(Rect2(2, -6, 6, 12), icon_color)
		"health":
			draw_rect(Rect2(-3, -9, 6, 18), icon_color)
			draw_rect(Rect2(-9, -3, 18, 6), icon_color)
		"ammo":
			draw_circle(Vector2(0, 0), 6, icon_color)
		"utility":
			# Gear-like icon
			for i in range(6):
				var a = i * PI / 3
				draw_rect(Rect2(Vector2(cos(a), sin(a)) * 8 - Vector2(2,2), Vector2(4,4)), icon_color)
			draw_arc(Vector2.ZERO, 6, 0, TAU, 16, icon_color, 2.0)
			
	# Proximity Label
	var players = get_tree().get_nodes_in_group("players")
	var show_label = false
	for p in players:
		if p.global_position.distance_to(global_position) < 300.0:
			show_label = true
			break
			
	if show_label:
		var label_color = Color.WHITE
		label_color.a = 0.8
		draw_string(ThemeDB.fallback_font, Vector2(-60, -radius - 15), pickup_name, HORIZONTAL_ALIGNMENT_CENTER, 120, 16, label_color)

func _process(_delta):
	if color == Color.WHITE:
		_update_color()
	queue_redraw()

@rpc("any_peer", "call_local")
func pickup_collected(picker_id: int, mount_index: int):
	# Usually called by server or by client requesting collection
	if not multiplayer.is_server():
		return
	
	var player = get_tree().current_scene.find_child(str(picker_id), true, false)
	
	print("[Pickup] collected: ", pickup_name, " by ", picker_id, " (Player found: ", (player != null), ")")
	
	if player:
		if pickup_type == "weapon" and item_scene:
			player.drop_weapon(mount_index)
			player.equip_weapon.rpc(mount_index, item_scene.resource_path)
			# Notify manager for RL rewards
			var game_node = get_tree().current_scene
			if game_node.has_method("record_pickup"):
				game_node.record_pickup(picker_id, pickup_type)
		elif pickup_type == "utility" and item_scene:
			player.drop_weapon(mount_index) # Utilities go to weapon mounts for now
			player.equip_weapon.rpc(mount_index, item_scene.resource_path)
			var game_node = get_tree().current_scene
			if game_node.has_method("record_pickup"):
				game_node.record_pickup(picker_id, pickup_type)
		elif pickup_type == "health":
			if player.has_method("heal"):
				player.heal(50)
				var game_node = get_tree().current_scene
				if game_node.has_method("record_pickup"):
					game_node.record_pickup(picker_id, pickup_type)
		elif pickup_type == "ammo":
			if player.has_method("add_ammo"):
				player.add_ammo(50)
				var game_node = get_tree().current_scene
				if game_node.has_method("record_pickup"):
					game_node.record_pickup(picker_id, pickup_type)
	
	if pickup_type == "gem":
		# Increment global gem count via GameManager (RPC)
		var game_node = get_tree().current_scene # Game node
		if game_node.has_method("increment_gem_count"):
			game_node.increment_gem_count() 
	
	# Remove from groups immediately so AI stops targeting it this frame
	remove_from_group("pickups")
	remove_from_group("gems")
	
	# Remove this pickup from all clients
	queue_free()
