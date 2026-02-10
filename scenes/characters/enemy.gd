extends CharacterBody2D

signal enemy_damaged(amount: float, attacker_id: int)
signal enemy_killed(attacker_id: int)

enum Tier { EASY, SCOUT, HEAVY }

@export var tier: Tier = Tier.EASY:
	set(val):
		tier = val
		if is_inside_tree():
			_setup_tier()
			queue_redraw()
@export var max_hp: float = 50.0
@export var speed: float = 200.0
@export var color_theme: Color = Color.GRAY:
	set(val):
		color_theme = val
		queue_redraw()
@export var attack_range: float = 400.0
@export var detection_range: float = 700.0 # ~3/4 of a screen before enemy notices

var current_hp: float
@onready var mounts = [$MountLeft, $MountRight, $MountFront]

func _ready():
	current_hp = max_hp
	collision_layer = 4 # Layer 3: Enemy
	add_to_group("enemies")
	
	if multiplayer.is_server():
		_setup_tier()
		_equip_weapons_for_tier()
	
	queue_redraw()

func _setup_tier():
	match tier:
		Tier.EASY:
			max_hp = 40.0
			speed = 150.0
			color_theme = Color.GRAY
		Tier.SCOUT:
			max_hp = 30.0
			speed = 300.0
			# Color set by spawner
		Tier.HEAVY:
			max_hp = 150.0
			speed = 100.0
			# Color set by spawner
	current_hp = max_hp

func _equip_weapons_for_tier():
	# Clear existing weapons
	for mount in mounts:
		for child in mount.get_children():
			child.queue_free()
	
	match tier:
		Tier.EASY:
			# 1 Pellet Gun (Front)
			equip_weapon(2, "res://scenes/weapons/pellet_gun.tscn")
		Tier.SCOUT:
			# 2 Pellet Guns (Left + Right)
			equip_weapon(0, "res://scenes/weapons/pellet_gun.tscn")
			equip_weapon(1, "res://scenes/weapons/pellet_gun.tscn")
		Tier.HEAVY:
			# 1 Machine Gun (Front)
			equip_weapon(2, "res://scenes/weapons/machine_gun.tscn")

func equip_weapon(mount_index: int, weapon_path: String):
	if mount_index < 0 or mount_index >= mounts.size():
		return
	
	var mount = mounts[mount_index]
	
	# Clear existing
	for child in mount.get_children():
		child.queue_free()
	
	if weapon_path != "":
		var weapon_pkg = load(weapon_path)
		if weapon_pkg:
			var weapon = weapon_pkg.instantiate()
			mount.add_child(weapon)

func _physics_process(delta):
	if multiplayer.is_server():
		var target = _get_nearest_player()
		if target:
			var to_target = (target.global_position - global_position)
			var dist = to_target.length()
			var dir = to_target.normalized()
			
			# Move towards player if outside attack range
			if dist > attack_range * 0.7:
				velocity = velocity.move_toward(dir * speed, 1000 * delta)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
				
			rotation = lerp_angle(rotation, dir.angle(), 5.0 * delta)
			
			if dist < attack_range:
				_fire_all_weapons(true, true) # Held
			else:
				_fire_all_weapons(false, false)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
			_fire_all_weapons(false, false)
		
		move_and_slide()

func _get_nearest_player():
	var nearest = null
	var min_dist = detection_range # Only detect players within this range
	for player in get_tree().get_nodes_in_group("players"):
		var dist = global_position.distance_to(player.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = player
	return nearest

func take_damage(amount: float, attacker_id: int):
	if not multiplayer.is_server(): return
	
	current_hp -= amount
	enemy_damaged.emit(amount, attacker_id)
	
	# Spawn damage particles (50% chance)
	ParticleSpawner.spawn_damage(global_position)
	if current_hp <= 0:
		die(attacker_id)

func die(attacker_id: int = -1):
	print("Enemy died")
	enemy_killed.emit(attacker_id)
	# Death explosion - use the enemy's color theme
	ParticleSpawner.spawn_death(global_position, color_theme)
	queue_free()

func _fire_all_weapons(just_pressed: bool, held: bool):
	for mount in mounts:
		if mount.get_child_count() > 0:
			var weapon = mount.get_child(0)
			if weapon.has_method("trigger"):
				weapon.trigger(just_pressed, held)

func _draw():
	var radius = 24.0
	var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.05
	var r = radius * pulse
	
	# Draw mount point indicators (below body)
	for m in mounts:
		if m and m.get_child_count() > 0:
			draw_circle(m.position, 6.0, color_theme * Color(1,1,1,0.3))
			draw_circle(m.position, 4.0, Color.BLACK)
			draw_circle(m.position, 2.0, color_theme)
			draw_line(Vector2.ZERO, m.position, color_theme.darkened(0.5), 1.5)
	
	# Glow backing
	draw_circle(Vector2.ZERO, r + 4, color_theme * Color(1, 1, 1, 0.2))
	
	# Draw Shape based on tier
	match tier:
		Tier.EASY: # Circle
			draw_circle(Vector2.ZERO, r - 2, Color.BLACK)
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, color_theme, 3.0, true)
		Tier.SCOUT: # Triangle
			var points = PackedVector2Array([
				Vector2(r, 0),
				Vector2(r, 0).rotated(TAU/3),
				Vector2(r, 0).rotated(2*TAU/3),
				Vector2(r, 0)
			])
			draw_colored_polygon(points, Color.BLACK)
			draw_polyline(points, color_theme, 3.0)
		Tier.HEAVY: # Square
			var s = r * 0.8
			var points = PackedVector2Array([
				Vector2(-s, -s), Vector2(s, -s),
				Vector2(s, s), Vector2(-s, s),
				Vector2(-s, -s)
			])
			draw_colored_polygon(points, Color.BLACK)
			draw_polyline(points, color_theme, 4.0)

	# Eyes (Forward looking)
	var eye_dist = 8.0
	var eye_size = 3.0
	draw_circle(Vector2(eye_dist, -6), eye_size, Color.WHITE)
	draw_circle(Vector2(eye_dist, 6), eye_size, Color.WHITE)
