extends CharacterBody2D

const SPEED = 600.0
const ACCEL = 2500.0
const FRICTION = 2000.0

@export var player_id: int = 1:
	set(id):
		player_id = id
		set_multiplayer_authority(id)
		# Check if node exists before accessing (setter can be called before _ready)
		if has_node("MultiplayerSynchronizer"):
			$MultiplayerSynchronizer.set_multiplayer_authority(id)

func _ready():
	# Ensure authority is set once ready
	# Set authority on the Player node itself (controls processing)
	set_multiplayer_authority(player_id)
	
	var sync_node = get_node_or_null("MultiplayerSynchronizer")
	if sync_node:
		sync_node.set_multiplayer_authority(player_id)
	else:
		print("CRITICAL ERROR: MultiplayerSynchronizer missing in Player scene!")

@onready var mount_left = $MountLeft
@onready var mount_right = $MountRight
@onready var mount_top = $MountTop
@onready var mounts = [mount_left, mount_right, mount_top]

func _physics_process(delta):
	if is_multiplayer_authority():
		_handle_input(delta)
	
	move_and_slide()

func _handle_input(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		velocity = velocity.move_toward(direction * SPEED, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	# Aiming (for mounts/visuals)
	# Use raw_aim from _physics_process if possible, but Input here works too
	var aim_dir = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim_dir.length() > 0.1:
		rotation = aim_dir.angle()
		# print("Rotation set to: ", rotation)
	
	# Firing
	if Input.is_action_pressed("fire_left"):
		_fire_mount(0)
	if Input.is_action_pressed("fire_right"):
		_fire_mount(1)
	if Input.is_action_pressed("fire_top"):
		_fire_mount(2)

func _fire_mount(index: int):
	# TODO: Call use() on equipped item
	print("Firing mount ", index)

func _draw():
	# vibrant yellow circle for player with dark center
	# Outline / Body
	draw_circle(Vector2.ZERO, 32.0, Color.YELLOW) # Outer (Stroke color)
	draw_circle(Vector2.ZERO, 28.0, Color(0.1, 0.1, 0.1)) # Inner (Background)
	
	# Directional indicator
	draw_line(Vector2.ZERO, Vector2(40, 0), Color.RED, 6.0)
	
	# Debug Input Visualization
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length() > 0:
		draw_line(Vector2.ZERO, input_dir * 50, Color.GREEN, 4.0)

	# Debug Aim Visualization
	var aim_dir = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim_dir.length() > 0:
		draw_line(Vector2.ZERO, aim_dir * 50, Color.BLUE, 4.0)
		# print("Aim Input: ", aim_dir) # Debug print
	
	# Authority Debug
	var auth_color = Color.GREEN if is_multiplayer_authority() else Color.RED
	draw_circle(Vector2(0, -40), 5.0, auth_color)

func _process(_delta):
	queue_redraw() # Continuous redraw for debug inputs

