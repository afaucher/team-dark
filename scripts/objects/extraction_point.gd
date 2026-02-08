extends Area2D

var is_active: bool = false
var pulse_time: float = 0.0

func _ready():
	monitoring = false
	monitorable = true
	is_active = false
	add_to_group("extraction")
	body_entered.connect(_on_body_entered)

@rpc("any_peer", "call_local", "reliable")
func activate():
	is_active = true
	monitoring = true 
	print("EXTRACTION POINT ACTIVATED!")
	queue_redraw()

func _process(delta):
	if is_active:
		pulse_time += delta
		queue_redraw()

func _draw():
	var color = Color(0, 1, 0) if is_active else Color(0.3, 0.3, 0.3, 0.5)
	var radius = 60.0
	
	if is_active:
		var pulse = 1.0 + sin(pulse_time * 5.0) * 0.1
		var current_radius = radius * pulse
		
		# Inner Glow
		draw_circle(Vector2.ZERO, current_radius, color * 0.2)
		# Outer Ring
		draw_arc(Vector2.ZERO, current_radius, 0, TAU, 32, color, 4.0, true)
		
		# "EXTRACT" text?
		draw_string(ThemeDB.fallback_font, Vector2(-40, 5), "EXTRACT", HORIZONTAL_ALIGNMENT_CENTER, 80, 16, color)
	else:
		# Inactive marker
		draw_circle(Vector2.ZERO, radius, color * 0.2)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 16, color, 2.0, true)
		draw_string(ThemeDB.fallback_font, Vector2(-40, 5), "LOCKED", HORIZONTAL_ALIGNMENT_CENTER, 80, 16, color)

func _on_body_entered(body):
	if not is_active: return
	if not multiplayer.is_server(): return
	
	if body.is_in_group("players"):
		print("Player ", body.name, " entered extraction zone!")
		var game = get_tree().current_scene
		if game.has_method("trigger_win"):
			game.trigger_win.rpc(body.player_id)
