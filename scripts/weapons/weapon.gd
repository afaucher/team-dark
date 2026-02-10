extends Node2D

# Base weapon script for enemies and players

@export var weapon_name: String = "Generic Weapon"
@export var projectile_scene: PackedScene
@export var fire_rate: float = 0.5
@export var damage: float = 10.0
@export var projectile_speed: float = 1000.0

var can_fire: bool = true
var fire_timer: Timer

func _ready():
	fire_timer = Timer.new()
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	add_child(fire_timer)
	queue_redraw()

func trigger(just_pressed: bool, held: bool):
	if (just_pressed or held) and can_fire:
		fire()

func fire():
	if not can_fire: return
	can_fire = false
	fire_timer.start()
	
	if multiplayer.is_server():
		var proj = projectile_scene.instantiate()
		var p_root = get_tree().current_scene.get_node_or_null("Projectiles")
		if not p_root:
			p_root = get_tree().current_scene
			
		p_root.add_child(proj)
		var owner_id = get_parent().get_parent().player_id if get_parent().get_parent().has_method("get_player_id") else 0
		proj.setup(global_position, Vector2.RIGHT.rotated(global_rotation), projectile_speed, damage, owner_id)
	
	queue_redraw()

func _on_fire_timer_timeout():
	can_fire = true
	queue_redraw()

func _draw():
	# Default weapon graphic for subclasses
	var barrel_length = 20.0
	var barrel_width = 8.0
	var color = Color(0.5, 0.5, 1.0, 1.0) # Light blue
	
	draw_line(Vector2.ZERO, Vector2(barrel_length, 0), color, 2.0)
	draw_arc(Vector2.ZERO, 5.0, 0, TAU, 8, color, 1.5)
	
	if can_fire:
		draw_circle(Vector2(barrel_length, 0), 2.0, Color.WHITE)
