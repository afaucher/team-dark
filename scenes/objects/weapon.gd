class_name Weapon
extends MountableItem

@export var projectile_scene: PackedScene
@export var fire_rate: float = 0.5
@export var damage: float = 10.0
@export var projectile_speed: float = 400.0
@export var spread_degrees: float = 0.0

var _can_fire: bool = true
var _timer: Timer

func _ready():
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = fire_rate
	_timer.timeout.connect(func(): _can_fire = true)
	add_child(_timer)

func use():
	if _can_fire and projectile_scene:
		_fire()
		_can_fire = false
		_timer.start()

func _fire():
	# Calculate direction based on user's rotation or aim
	var dir = Vector2.RIGHT.rotated(global_rotation)
	if spread_degrees > 0:
		dir = dir.rotated(deg_to_rad(randf_range(-spread_degrees, spread_degrees)))
	
	_spawn_projectile(global_position, dir)

func _spawn_projectile(pos: Vector2, dir: Vector2):
	# Projectile spawning logic needs to be multiplayer aware
	# For now, we'll just emit a signal or call a global spawner
	# In a real networked game, this would likely be an RPC
	if multiplayer.is_server():
		var proj = projectile_scene.instantiate()
		proj.setup(pos, dir, projectile_speed, damage, user.player_id if "player_id" in user else 1)
		get_tree().root.add_child(proj)
	else:
		# If client authoritative local effects are needed, do them here
		# But usually we request the server to fire
		rpc_id(1, "request_fire", pos, dir)

@rpc("any_peer", "call_local")
func request_fire(pos, dir):
	if multiplayer.is_server():
		_spawn_projectile(pos, dir)
