extends Area2D

class_name Pickup

@export var pickup_name: String = "Generic Pickup"
@export var pickup_type: String = "weapon" # weapon, health, ammo, gem
@export var item_scene: PackedScene # The weapon scene to equip
@export var item_scene_path: String = "" # Path for network sync

var radius: float = 24.0
var color: Color = Color.WHITE

func _ready():
	# Ensure it has a collision shape
	if get_child_count() == 0:
		var collision = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = radius + 10.0
		collision.shape = circle
		add_child(collision)
	
	add_to_group("pickups")
	
	print("[Pickup] Spawned: ", pickup_name, " type: ", pickup_type, " at ", global_position)
	
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

func _draw():
	# Vector Art Style Pickup
	var inner_radius = radius * 0.6
	var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.1
	var current_radius = radius * pulse
	
	# Glow
	draw_circle(Vector2.ZERO, current_radius + 4, color * Color(1,1,1,0.2))
	
	# Outer Ring
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 32, color, 3.0, true)
	
	# Inner Fill (Black)
	draw_circle(Vector2.ZERO, inner_radius, Color.BLACK)
	
	# Type Icon (Simplified)
	match pickup_type:
		"weapon":
			draw_rect(Rect2(-5, -2, 10, 4), color)
			draw_rect(Rect2(2, -4, 4, 8), color)
		"health":
			draw_rect(Rect2(-2, -6, 4, 12), color)
			draw_rect(Rect2(-6, -2, 12, 4), color)
		"ammo":
			draw_circle(Vector2(0, 0), 4, color)
		"gem":
			var points = PackedVector2Array([
				Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0)
			])
			draw_colored_polygon(points, color)

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
	if not player: return

	print("Pickup collectible: ", pickup_name, " for player ", picker_id, " mount ", mount_index)
	
	if pickup_type == "weapon" and item_scene:
		# Before equipping, player should drop existing weapon?
		# The prompt says: "When they switch they should drop the current item they have."
		player.drop_weapon(mount_index)
		player.equip_weapon.rpc(mount_index, item_scene.resource_path)
	elif pickup_type == "health":
		if player.has_method("heal"):
			player.heal(50)
	elif pickup_type == "ammo":
		if player.has_method("add_ammo"):
			player.add_ammo(50)
	
	# Remove this pickup from all clients
	queue_free()
