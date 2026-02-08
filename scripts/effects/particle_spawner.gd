extends Node

# Spawn damage particles (red) - 50% chance
func spawn_damage(pos: Vector2):
	if randf() > 0.5:
		return # 50% chance to skip
	_spawn_particles(pos, Color.RED, 12, 250.0)

# Spawn impact particles (blue) - small chance
func spawn_impact(pos: Vector2):
	if randf() > 0.15: # 15% chance
		return
	_spawn_particles(pos, Color(0.3, 0.5, 1.0), 8, 200.0)

# Spawn death explosion (many particles)
func spawn_death(pos: Vector2, color: Color = Color.WHITE):
	# 1. Main Debris (Brighter, colored)
	_spawn_particles(pos, color * 1.5, 60, 500.0, 2.0)
	
	# 2. Core Flash (Bright White, small high density)
	_spawn_particles(pos, Color(3, 3, 3), 20, 150.0, 0.5, 2.0)
	
	# 3. Shockwave (expanding ring)
	_spawn_shockwave(pos, color * 2.0)

func _spawn_shockwave(pos: Vector2, color: Color):
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 40
	particles.lifetime = 0.6
	
	# Ring Shape? Godot 4 CPUParticles2D has RING? 
	# If not, we use Sphere with shell? 
	# Actually, Points or Sphere is mostly what's used. Let's use Sphere but with high velocity and 0 gravity.
	
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 2.0
	
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 600.0
	particles.initial_velocity_max = 600.0 # Uniform speed for ring effect
	particles.damping_min = 500.0
	particles.damping_max = 500.0 # Slow down fast
	
	# Visuals
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = color
	
	# Fade
	var gradient = Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0))
	particles.color_ramp = gradient
	
	particles.global_position = pos
	particles.z_index = 25
	
	get_tree().current_scene.add_child(particles)
	
	get_tree().create_timer(1.0).timeout.connect(func(): 
		if is_instance_valid(particles):
			particles.queue_free()
	)

func _spawn_particles(pos: Vector2, color: Color, count: int, speed: float, lifetime: float = 0.5, radius: float = 15.0):
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = count
	particles.lifetime = lifetime
	particles.speed_scale = 1.5
	
	# Emission shape
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = radius
	
	# Movement
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	particles.gravity = Vector2(0, 200)
	
	# Visual
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 7.0
	particles.color = color
	
	# Fade out
	var gradient = Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0))
	particles.color_ramp = gradient
	
	particles.global_position = pos
	particles.z_index = 25 # Above most things
	
	# Add to the current scene's root so particles stay even if spawner moves
	get_tree().current_scene.add_child(particles)
	
	# Auto-cleanup after particles finish
	get_tree().create_timer(lifetime + 0.5).timeout.connect(func(): 
		if is_instance_valid(particles):
			particles.queue_free()
	)
