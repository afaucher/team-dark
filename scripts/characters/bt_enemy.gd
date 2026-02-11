extends CharacterBody2D

## BT_Enemy
## New base enemy class that relies on Beehave for all high-level logic.

signal enemy_damaged(amount: float, attacker_id: int)
signal enemy_killed(attacker_id: int)

@export var max_hp: float = 50.0
@export var speed: float = 200.0
@export var color_theme: Color = Color.WHITE
@export var tier: int = 1
@export var shape_type: String = "circle" # circle, triangle, square

var target_node: Node2D = null

var current_hp: float
@onready var mounts = [$MountLeft, $MountRight, $MountFront]
@onready var beehave_tree = $BeehaveTree

func _ready():
	if color_theme == Color.WHITE:
		color_theme = ThemeManager.get_enemy_color(tier)
		
	current_hp = max_hp
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 7
	
	if multiplayer.is_server():
		_setup_logic()
		if "swarm" in name.to_lower():
			add_to_group("swarm")
	
	queue_redraw()

func _setup_logic():
	if color_theme == Color.WHITE:
		color_theme = ThemeManager.get_enemy_color(tier)
	# Always equip for testing
	_equip_random_loadout()

func _equip_random_loadout():
	# Front mount weapon
	var front_weapons = ["res://scenes/weapons/pellet_gun.tscn", "res://scenes/weapons/machine_gun.tscn"]
	equip_weapon(2, front_weapons.pick_random())
	
	# Side utility (optional)
	if randf() < 0.2:
		# Placeholder for utility scenes
		pass

func _physics_process(delta):
	if not multiplayer.is_server(): return
	
	# Beehave handles 'velocity' calculation
	if target_node and is_instance_valid(target_node):
		var target_dir = (target_node.global_position - global_position).normalized()
		rotation = lerp_angle(rotation, target_dir.angle(), 10.0 * delta)
	elif velocity.length() > 10.0:
		rotation = lerp_angle(rotation, velocity.angle(), 10.0 * delta)
		
	# Proximity fallback (Mostly for Kamikaze)
	if has_method("detonate"):
		var players = get_tree().get_nodes_in_group("players")
		for p in players:
			if global_position.distance_to(p.global_position) < 40.0:
				detonate()
				break
				
	move_and_slide()

func detonate():
	# Virtual method for subclasses (e.g. Kamikaze)
	pass

func take_damage(amount: float, attacker_id: int):
	current_hp -= amount
	enemy_damaged.emit(amount, attacker_id)
	ParticleSpawner.spawn_damage(global_position)
	if current_hp <= 0:
		die(attacker_id)

func die(attacker_id: int):
	if multiplayer.is_server():
		_drop_loot()
	enemy_killed.emit(attacker_id)
	ParticleSpawner.spawn_death(global_position, color_theme)
	queue_free()

func _drop_loot():
	# 20% chance to drop a simple pickup
	if randf() > 0.2: return
	
	var pickup_pkg = load("res://scenes/objects/pickup.tscn")
	var p = pickup_pkg.instantiate()
	
	# Determine type
	var r = randf()
	if r < 0.6:
		p.pickup_type = "health"
		p.pickup_name = "Health Kit"
	elif r < 0.9:
		p.pickup_type = "weapon"
		p.pickup_name = "Pellet Gun"
		# Needs item_scene_path or logic to match
	else:
		p.pickup_type = "gem" # Rare drop? No, lets keep gems separate for now.
		return
		
	var pickups_node = get_tree().current_scene.find_child("Pickups", true, false)
	if pickups_node:
		p.global_position = global_position
		pickups_node.add_child(p, true)

func _fire_all_weapons(just_pressed: bool, held: bool):
	for mount in mounts:
		for child in mount.get_children():
			if child.has_method("trigger"):
				child.trigger(just_pressed, held)

func equip_weapon(mount_index: int, weapon_path: String):
	if mount_index < 0 or mount_index >= mounts.size(): return
	var mount = mounts[mount_index]
	for c in mount.get_children(): c.queue_free()
	
	var weapon_pkg = load(weapon_path)
	if weapon_pkg:
		var weapon = weapon_pkg.instantiate()
		mount.add_child(weapon)
	
	queue_redraw()

func _draw():
	var radius = 24.0
	var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.05
	var r = radius * pulse
	var display_color = color_theme
	
	# Draw mount point indicators (below body)
	for m in mounts:
		if m and m.get_child_count() > 0:
			draw_circle(m.position, 6.0, display_color * Color(1,1,1,0.3))
			draw_circle(m.position, 4.0, Color.BLACK)
			draw_circle(m.position, 2.0, display_color)
			draw_line(Vector2.ZERO, m.position, display_color.darkened(0.5), 1.5)
	
	# Glow backing
	draw_circle(Vector2.ZERO, r + 4, display_color * Color(1, 1, 1, 0.2))
	
	# Draw Shape
	match shape_type:
		"circle":
			draw_circle(Vector2.ZERO, r - 2, Color.BLACK)
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, display_color * 1.5, 3.0, true)
		"triangle":
			var points = PackedVector2Array([
				Vector2(r, 0),
				Vector2(r, 0).rotated(TAU/3),
				Vector2(r, 0).rotated(2*TAU/3)
			])
			draw_colored_polygon(points, Color.BLACK)
			# Close polyline manually
			var line_points = points
			line_points.append(points[0])
			draw_polyline(line_points, color_theme, 3.0)
		"square":
			var s = r * 0.8
			var points = PackedVector2Array([
				Vector2(-s, -s), Vector2(s, -s),
				Vector2(s, s), Vector2(-s, s)
			])
			draw_colored_polygon(points, Color.BLACK)
			var line_points = points
			line_points.append(points[0])
			draw_polyline(line_points, color_theme, 4.0)
		"hex":
			var points = PackedVector2Array()
			for i in range(6):
				points.append(Vector2(r, 0).rotated(i * TAU/6))
			draw_colored_polygon(points, Color.BLACK)
			var line_points = points
			line_points.append(points[0])
			draw_polyline(line_points, color_theme, 3.0)

	# Eyes (Forward looking)
	var eye_dist = 8.0
	var eye_size = 3.0
	draw_circle(Vector2(eye_dist, -6), eye_size, Color.WHITE)
	draw_circle(Vector2(eye_dist, 6), eye_size, Color.WHITE)

func _process(_delta):
	# Continuous redraw for pulsing effect
	queue_redraw()
