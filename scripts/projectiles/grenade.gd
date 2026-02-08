extends Area2D

@export var speed: float = 500.0
@export var friction: float = 300.0
@export var damage: float = 40.0
@export var blast_radius: float = 150.0
@export var lifetime: float = 2.0

var velocity: Vector2
var attacker_id: int = 1
var owner_node: Node = null
var spawn_protection: float = 0.05

func _ready():
	add_to_group("projectiles")
	set_as_top_level(true)
	z_index = 15
	
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(explode)

func _physics_process(delta):
	if spawn_protection > 0:
		spawn_protection -= delta
		
	# Move and handle bounces (simple manual bounce logic)
	var motion = velocity * delta
	var collision = _check_collision(motion)
	if collision:
		velocity = velocity.bounce(collision.normal) * 0.7 # Lose energy on bounce
		motion = velocity * delta
	
	position += motion
	
	# Apply friction
	if velocity.length() > 20:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	queue_redraw()

func _check_collision(motion: Vector2):
	# Using PhysicsDirectSpaceState2D for simple raycast/shape intersection
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + motion)
	query.exclude = [self, owner_node] if owner_node else [self]
	query.collision_mask = 1 # World layer
	
	var result = space_state.intersect_ray(query)
	if result:
		return result
	return null

func _on_body_entered(body):
	if spawn_protection > 0 or body == owner_node:
		return
	
	if body.is_in_group("enemies") or body.is_in_group("players"):
		explode()

func explode():
	# Visuals
	ParticleSpawner.spawn_death(global_position, Color(1, 0.4, 0)) # Orange blast
	
	# Shake camera if nearby? (Future polish)
	
	# Deal damage in radius
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = blast_radius
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 6 # Layers 2 (Player) and 3 (Enemy)
	
	var results = space_state.intersect_shape(query)
	var damaged_entities = []
	for result in results:
		var body = result.collider
		if body.has_method("take_damage") and not body in damaged_entities:
			# Calculate falloff damage based on distance? 
			# For now, flat damage for simplicity.
			body.take_damage(damage, attacker_id)
			damaged_entities.append(body)
	
	queue_free()

func _draw():
	# Vector Style Grenade
	var r = 8.0
	var color = Color(1.0, 0.2, 0.0, 1.0) # Red-Orange HDR
	
	# Inner glow
	draw_circle(Vector2.ZERO, r + 4, color * Color(1, 1, 1, 0.2))
	# Core
	draw_circle(Vector2.ZERO, r, Color.BLACK)
	draw_arc(Vector2.ZERO, r, 0, TAU, 16, color, 2.0)
	# Pulsing light
	var pulse = 0.5 + sin(Time.get_ticks_msec() * 0.01) * 0.5
	draw_circle(Vector2.ZERO, 3.0, color * pulse)
