@tool
extends "res://addons/godot_rl_agents/sensors/sensors_2d/ISensor2D.gd"

# SectorSensor2D: Divides the view into N sectors and reports the nearest VISIBLE target in each.
class_name SectorSensor2D

@export_flags_2d_physics var collision_mask := 1:
	get:
		return collision_mask
	set(value):
		collision_mask = value
		_update()

@export var n_sectors := 16:
	get:
		return n_sectors
	set(value):
		# Must be > 0
		n_sectors = max(1, value)
		_update()

@export_range(5, 3000, 5.0) var max_range := 1000.0:
	get:
		return max_range
	set(value):
		max_range = value
		_update()

@export var debug_draw := true:
	get:
		return debug_draw
	set(value):
		debug_draw = value
		_update()

# Internal state
var _sector_targets = [] # Stores [distance, target_node] for each sector
var _sector_status = [] # Stores 0.0 (empty) to 1.0 (close) for debug drawing

func _update():
	pass # No node spawning needed, purely logic-based

func _physics_process(_delta: float) -> void:
	# Keep debug visuals high-reactivity (per-frame)
	if DebugManager.show_debug:
		_perform_detection()

func _ready() -> void:
	pass

func get_observation() -> Array:
	return _perform_detection()

func _perform_detection() -> Array:
	var result = []
	var space_state = get_world_2d().direct_space_state
	var my_pos = global_position
	var sector_angle_step = TAU / float(n_sectors)
	
	# Prepare sector buckets
	var sectors = []
	for i in range(n_sectors):
		sectors.append([]) # List of enemies in this sector
		
	# 1. Gather all potential targets (Enemies) within range
	# We use a PhysicsShapeQuery (Circle) to find them efficiently
	var shape = CircleShape2D.new()
	shape.radius = max_range
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, my_pos)
	query.collision_mask = collision_mask # Layer 4 (Enemies)
	
	# Exclude the actual Player body, not the controller node
	var controller = get_parent()
	if controller and "player" in controller and is_instance_valid(controller.player):
		query.exclude = [controller.player.get_rid()]
	
	var hits = space_state.intersect_shape(query)
	
	# 2. Sort targets into sectors
	for hit in hits:
		var target = hit.collider
		if not is_instance_valid(target): continue
		
		var rel_vec = target.global_position - my_pos
		var dist = rel_vec.length()
		var angle = rel_vec.angle() # -PI to PI
		
		# Normalize angle to 0..TAU relative to player rotation
		# Actually, standard sensors are usually global or local? 
		# RaySensor is usually local to rotation. Let's make this local.
		var local_angle = wrapf(angle - global_rotation, -PI, PI)
		
		# Map angle to sector index (0 to n-1)
		# Sector 0 is centered on 0 degrees (Right)
		# Angle range for sector i: (i * step) +/- (step/2)
		var step = TAU / n_sectors
		var index = int(round(local_angle / step)) % n_sectors
		if index < 0: index += n_sectors
		
		sectors[index].append({"node": target, "dist": dist})
		
	# 3. Process each sector
	_sector_status.resize(n_sectors)
	_sector_targets.resize(n_sectors)
	
	for i in range(n_sectors):
		var enemies_in_sector = sectors[i]
		
		if enemies_in_sector.size() == 0:
			result.append(-1.0) # Explicit "None" signal
			_sector_status[i] = -1.0
			_sector_targets[i] = null
			continue
			
		# Sort by distance (nearest first)
		enemies_in_sector.sort_custom(func(a, b): return a.dist < b.dist)
		
		var found_visible = false
		var final_dist = 0.0
		var visible_target = null
		
		# Check visibility from nearest to farthest
		for enemy_data in enemies_in_sector:
			var target = enemy_data.node
			var ray_query = PhysicsRayQueryParameters2D.create(my_pos, target.global_position)
			ray_query.collision_mask = 1 # Only check World Walls (Layer 1)
			# No need to exclude enemies since we mask only Layer 1
			
			var ray_result = space_state.intersect_ray(ray_query)
			
			if not ray_result: # No wall hit -> Visible!
				final_dist = clamp(enemy_data.dist, 0.0, max_range)
				# 0.0 (Touch) to 1.0 (Max Range)
				var obs_val = final_dist / max_range
				result.append(obs_val)
				
				found_visible = true
				_sector_status[i] = obs_val
				_sector_targets[i] = target
				visible_target = target
				break # Found the nearest visible, move to next sector
		
		if not found_visible:
			result.append(-1.0) # None
			_sector_status[i] = -1.0
			_sector_targets[i] = null

	queue_redraw()
	return result

func _draw():
	if not DebugManager.show_debug:
		return

	var viz_radius = max_range
	var step = TAU / n_sectors
	var half_step = step / 2.0
	
	# DRAW BACKGROUND GRID (Scaled to Detection Range)
	draw_arc(Vector2.ZERO, viz_radius, 0, TAU, 64, Color(0.3, 0.3, 0.3, 0.3), 3.0)
	draw_arc(Vector2.ZERO, viz_radius * 0.75, 0, TAU, 64, Color(0.3, 0.3, 0.3, 0.2), 2.0)
	draw_arc(Vector2.ZERO, viz_radius * 0.5, 0, TAU, 64, Color(0.3, 0.3, 0.3, 0.2), 2.0)
	draw_arc(Vector2.ZERO, viz_radius * 0.25, 0, TAU, 64, Color(0.3, 0.3, 0.3, 0.2), 2.0)
	
	for i in range(n_sectors):
		var angle = i * step
		var val = _sector_status[i]
		
		# Define the wedge points for the FULL sector (background)
		var wedge_pts = PackedVector2Array([Vector2.ZERO])
		for j in range(6):
			var a = angle - half_step + (j * step / 5.0)
			wedge_pts.append(Vector2.RIGHT.rotated(a) * viz_radius)
		
		# Draw a slightly darker background for each wedge
		draw_polygon(wedge_pts, [Color(0.2, 0.2, 0.2, 0.15)])
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(angle - half_step) * viz_radius, Color(0.4, 0.4, 0.4, 0.2), 2.0)
		
		if val >= 0.0:
			# NEON GREEN SOLID-LOOKING GLOW
			var active_color = Color(0.0, 1.0, 0.0, 0.6) # Thick Solid Green
			
			# Draw the filled wedge
			draw_polygon(wedge_pts, [active_color])
			
			# EXTREMELY thick borders for solid look
			draw_arc(Vector2.ZERO, viz_radius, angle - half_step, angle + half_step, 16, Color.GREEN, 8.0)
			draw_arc(Vector2.ZERO, viz_radius + 4, angle - half_step, angle + half_step, 16, Color.WHITE, 2.0) # Highlight rim
			
			# Boundary lines (Thick)
			draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(angle - half_step) * viz_radius, Color.GREEN, 4.0)
			draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(angle + half_step) * viz_radius, Color.GREEN, 4.0)
			
			# 🎯 THE TARGET RETICLE (SOLID)
			var target = _sector_targets[i]
			if target and is_instance_valid(target):
				var target_local = to_local(target.global_position)
				# Thick direct pointer
				draw_line(Vector2.ZERO, target_local, Color.WHITE, 5.0)
				draw_line(Vector2.ZERO, target_local, Color.GREEN, 3.0)
				
				# Solid Concentric Reticle
				draw_circle(target_local, 22.0, Color.GREEN)
				draw_circle(target_local, 14.0, Color.WHITE)
				draw_circle(target_local, 7.0, Color.GREEN)
