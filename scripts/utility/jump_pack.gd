extends Node2D

@export var utility_name: String = "Jump Pack"
@export var impulse_strength: float = 1200.0
@export var cooldown: float = 2.0

var can_use: bool = true
var _timer: Timer

func _ready():
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = cooldown
	_timer.timeout.connect(_on_cooldown_timeout)
	add_child(_timer)
	_update_hud_status()

func trigger(just_pressed: bool, is_held: bool):
	if just_pressed and can_use:
		_apply_jump.rpc()

@rpc("any_peer", "call_local", "reliable")
func _apply_jump():
	var mount = get_parent()
	var player = mount.get_parent() if mount else null
	
	if player and player is CharacterBody2D:
		# Jump in the direction the player is aiming or moving
		# Rotation is easier to control
		var dir = Vector2.RIGHT.rotated(player.rotation)
		player.velocity = dir * impulse_strength
		
		# Visual effect
		ParticleSpawner.spawn_death(global_position, Color(1, 0.8, 0)) # Small puff
		
		can_use = false
		_timer.start()
		_update_hud_status()
		queue_redraw()

func _on_cooldown_timeout():
	can_use = true
	_update_hud_status()
	queue_redraw()

func _draw():
	# Simple Icon
	var color = Color(1, 1, 0, 1) if can_use else Color(0.3, 0.3, 0.3)
	draw_arc(Vector2.ZERO, 10, PI, TAU, 16, color, 3.0)
	draw_line(Vector2(-10, 0), Vector2(10, 0), color, 3.0)

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
					hud.update_weapon_status(idx, can_use, 1.0)
