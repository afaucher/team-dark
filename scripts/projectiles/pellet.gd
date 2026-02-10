extends Area2D

@export var speed: float = 800.0
@export var damage: float = 10.0
@export var max_distance: float = 1200.0

var traveled_distance: float = 0.0

var attacker_id: int = 1
var owner_node: Node = null # The entity that fired this projectile
var spawn_protection: float = 0.05 # Brief invulnerability to prevent self-hits

func _ready():
	add_to_group("projectiles")
	set_as_top_level(true) # Use global coordinates directly
	z_index = 15 # Consitent gameplay layer
	
	# Connect the body_entered signal for collision detection
	body_entered.connect(_on_body_entered)
	
	# Optional: Add a timer for lifetime as a fallback
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _physics_process(delta):
	if spawn_protection > 0:
		spawn_protection -= delta

	var move_step = speed * delta
	var direction = Vector2.RIGHT.rotated(rotation)
	var next_pos = global_position + direction * move_step
	
	# Raycast Check (CCD)
	# Mask 7 = Layer 1 (World), 2 (Player), 3 (Enemy)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, next_pos)
	query.exclude = [self, owner_node] if owner_node else [self]
	query.collision_mask = 7
	
	var result = space_state.intersect_ray(query)
	if result:
		# COLLISION DETECTED
		global_position = result.position
		_on_body_entered(result.collider)
		return

	position = next_pos
	traveled_distance += move_step
	
	if traveled_distance > max_distance:
		queue_free()
	
	queue_redraw()

func _on_body_entered(body):
	# Skip if still in spawn protection
	if spawn_protection > 0:
		return
	
	# Skip if this is the owner (prevent self-damage)
	if body == owner_node:
		return
	
	# Spawn impact particles (small chance of blue sparks)
	ParticleSpawner.spawn_impact(global_position)
	
	if body.has_method("take_damage"):
		body.take_damage(damage, attacker_id)
	
	queue_free()

func _input(event):
	if event.is_action_pressed("toggle_debug"):
		queue_redraw()

func _draw():
	# Neon Vector Style for Pellet
	var core_color = Color(2.0, 2.0, 2.0, 1.0) # Over-bright White
	var glow_color = Color(0.0, 1.5, 1.5, 1.0) # HDR Cyan
	
	# 1. Multi-layered Halo
	for i in range(3):
		var r = 4.0 + (i * 4.0)
		var a = 0.3 - (i * 0.1)
		draw_circle(Vector2.ZERO, r, glow_color * Color(1, 1, 1, a))
	
	# 2. Motion Trail (Photon Streak)
	# Draw a tapered trail
	var trail_length = 20.0
	var points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(-trail_length, -2),
		Vector2(-trail_length, 2)
	])
	draw_colored_polygon(points, glow_color * Color(1, 1, 1, 0.3))
	draw_line(Vector2.ZERO, Vector2(-trail_length, 0), glow_color, 2.0)
	
	# 3. Solid Core
	draw_circle(Vector2.ZERO, 2.5, core_color)
	
	# --- Debug Overlay (Toggle with F3) ---
	if DebugManager.show_debug:
		# Draw just a small authority indicator or nothing? 
		# User wanted them removed. I'll leave a single small dot.
		var label = "S" if is_multiplayer_authority() else "C"
		draw_string(ThemeDB.fallback_font, Vector2(8, -8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)
