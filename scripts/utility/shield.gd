extends Node2D

@export var weapon_name: String = "Energy Shield"
@export var duration: float = 3.0
@export var cooldown: float = 8.0
@export var shield_radius: float = 80.0

var is_active: bool = false
var can_use: bool = true
var _active_timer: Timer
var _cooldown_timer: Timer
var _shield_area: Area2D

func _ready():
	_active_timer = Timer.new()
	_active_timer.one_shot = true
	_active_timer.wait_time = duration
	_active_timer.timeout.connect(_on_duration_timeout)
	add_child(_active_timer)
	
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.wait_time = cooldown
	_cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(_cooldown_timer)
	
	_setup_shield_area()
	_update_hud_status()
	queue_redraw()

func _setup_shield_area():
	_shield_area = Area2D.new()
	_shield_area.collision_layer = 0 # Doesn't need its own layer
	_shield_area.collision_mask = 8 # Projectile layer
	_shield_area.monitoring = false
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = shield_radius
	col.shape = shape
	_shield_area.add_child(col)
	
	_shield_area.area_entered.connect(_on_projectile_entered)
	add_child(_shield_area)

func trigger(just_pressed: bool, is_held: bool):
	if just_pressed and can_use and not is_active:
		activate.rpc()

@rpc("any_peer", "call_local", "reliable")
func activate():
	is_active = true
	can_use = false
	_shield_area.monitoring = true
	_active_timer.start()
	_update_hud_status()
	queue_redraw()
	print("Shield Activated!")

func _on_duration_timeout():
	is_active = false
	_shield_area.monitoring = false
	_cooldown_timer.start()
	_update_hud_status()
	queue_redraw()
	print("Shield Deactivated!")

func _on_cooldown_timeout():
	can_use = true
	_update_hud_status()
	queue_redraw()
	print("Shield Ready!")

func _on_projectile_entered(area):
	if is_active and area.is_in_group("projectiles"):
		# Check if it's the user's projectile
		if "owner_node" in area:
			var user = get_parent().get_parent() # Mount -> Player
			if area.owner_node == user:
				return # Don't block own shots
				
		# Destroy enemy projectile
		ParticleSpawner.spawn_impact(area.global_position)
		area.queue_free()

func _draw():
	if is_active:
		var color = Color(0, 0.8, 1.0, 0.5) # Blue Glow
		var pulse = 0.8 + sin(Time.get_ticks_msec() * 0.01) * 0.1
		draw_circle(Vector2.ZERO, shield_radius * pulse, color * Color(1, 1, 1, 0.1))
		draw_arc(Vector2.ZERO, shield_radius * pulse, 0, TAU, 32, color, 3.0)
	elif not can_use:
		# Show cooldown spinner
		var progress = 1.0 - (_cooldown_timer.time_left / cooldown)
		draw_arc(Vector2.ZERO, 10, -PI/2, -PI/2 + progress * TAU, 16, Color.GRAY, 2.0)

func _update_hud_status():
	var parent = get_parent()
	if parent:
		var player = parent.get_parent()
		if player and player.is_multiplayer_authority():
			var idx = -1
			if "mounts" in player:
				for i in range(player.mounts.size()):
					if player.mounts[i] == parent:
						idx = i
						break
			if idx != -1:
				var hud = get_tree().root.find_child("HUD", true, false)
				if hud and hud.has_method("update_weapon_status"):
					var status_text = "ACTIVE" if is_active else ("READY" if can_use else "COOLDOWN")
					# Reuse update_weapon_status or similar
					hud.update_weapon_status(idx, can_use or is_active, 1.0 if can_use else 0.5)
