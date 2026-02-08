extends Area2D

@export var speed: float = 800.0
@export var damage: float = 10.0
@export var max_distance: float = 2000.0

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
	var move_step = speed * delta
	position += Vector2.RIGHT.rotated(rotation) * move_step
	traveled_distance += move_step
	
	if spawn_protection > 0:
		spawn_protection -= delta
	
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
		var time = Time.get_ticks_msec() / 1000.0
		var pulse = (sin(time * 10.0) + 1.0) * 0.5
		var debug_color = Color(1.0, 0, 0, 0.8) # Red
		
		# Pulsing Circle
		draw_arc(Vector2.ZERO, 20.0 + pulse * 10.0, 0, TAU, 32, debug_color, 2.0)
		
		# Rotating Crosshair
		var ang = time * 5.0
		for i in range(4):
			var v = Vector2.RIGHT.rotated(ang + i * PI/2) * 30.0
			draw_line(v * 0.5, v, debug_color, 3.0)
		
		# Authority Label
		var label = "S" if is_multiplayer_authority() else "C"
		draw_string(ThemeDB.fallback_font, Vector2(12, -12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.YELLOW)
