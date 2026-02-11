extends Control

enum WeaponType { NONE, PELLET_GUN, MACHINE_GUN, SHOTGUN, GRENADE_LAUNCHER, MISSILE_LAUNCHER, HEALTH_KIT }

var type: WeaponType = WeaponType.NONE:
	set(val):
		type = val
		queue_redraw()

var is_ready: bool = true:
	set(val):
		is_ready = val
		queue_redraw()

var ammo_ratio: float = 1.0:
	set(val):
		ammo_ratio = clamp(val, 0.0, 1.0)
		queue_redraw()

func _draw():
	var style = ThemeManager.current_hud_style
	match type:
		WeaponType.PELLET_GUN:
			_draw_pellet_gun(style)
		WeaponType.MACHINE_GUN:
			_draw_machine_gun(style)
		WeaponType.SHOTGUN:
			_draw_shotgun(style)
		WeaponType.GRENADE_LAUNCHER:
			_draw_grenade_launcher(style)
		WeaponType.MISSILE_LAUNCHER:
			_draw_missile_launcher(style)
		WeaponType.HEALTH_KIT:
			_draw_health_kit(style)

func _get_panel_style_params(style):
	var params = {
		"corner_radius": 0.0,
		"outline_width": 2.0,
		"hollow": false,
		"segmented": false
	}
	match style:
		ThemeManager.HUDStyle.SEGMENTED:
			params.segmented = true
			params.outline_width = 3.0
		ThemeManager.HUDStyle.MINIMALIST:
			params.corner_radius = 8.0
			params.hollow = true
			params.outline_width = 1.0
		ThemeManager.HUDStyle.TACTICAL:
			params.corner_radius = 2.0
			params.outline_width = 2.0
		ThemeManager.HUDStyle.COMBAT:
			params.outline_width = 4.0
	return params

func _draw_pellet_gun(style):
	var params = _get_panel_style_params(style)
	var color = ThemeManager.player_primary
	var barrel_length = 30.0
	var barrel_width = 12.0
	var rect = Rect2(-barrel_length/2, -barrel_width/2, barrel_length, barrel_width)
	
	if not params.hollow:
		draw_rect(rect, Color.BLACK, true)
	
	draw_rect(rect, color, false, params.outline_width)
	
	if params.segmented:
		draw_line(Vector2(0, -barrel_width/2), Vector2(0, barrel_width/2), color * 0.5, 1.0)

	if is_ready:
		draw_circle(Vector2(barrel_length/2, 0), 3.0, Color.WHITE)

func _draw_machine_gun(style):
	var params = _get_panel_style_params(style)
	var color = ThemeManager.proj_grenade_glow
	var barrel_length = 35.0
	var barrel_width = 15.0
	var rect = Rect2(-barrel_length/2, -barrel_width/2, barrel_length, barrel_width)
	
	if not params.hollow:
		draw_rect(rect, Color.BLACK, true)
	draw_rect(rect, color, false, params.outline_width)
	
	if ammo_ratio > 0:
		var bar_padding = 4.0
		var bar_rect = Rect2(-barrel_length/2 + bar_padding, -barrel_width/2 + bar_padding, (barrel_length - bar_padding*2) * ammo_ratio, barrel_width - bar_padding*2)
		draw_rect(bar_rect, Color.WHITE, true)

func _draw_shotgun(style):
	var params = _get_panel_style_params(style)
	var color = ThemeManager.player_primary
	var barrel_length = 30.0
	var barrel_width = 16.0
	var rect = Rect2(-barrel_length/2, -barrel_width/2, barrel_length, barrel_width)
	if not params.hollow:
		draw_rect(rect, Color.BLACK, true)
	draw_rect(rect, color, false, params.outline_width)
	draw_line(Vector2(-barrel_length/2, 0), Vector2(barrel_length/2, 0), color, 1.0)

func _draw_grenade_launcher(style):
	var params = _get_panel_style_params(style)
	var color = ThemeManager.proj_grenade_glow
	var size = 25.0
	if not params.hollow:
		draw_circle(Vector2.ZERO, size/2, Color.BLACK)
	draw_arc(Vector2.ZERO, size/2, 0, TAU, 32, color, params.outline_width)
	for i in range(6):
		var p = Vector2.RIGHT.rotated(i * TAU/6) * 6.0
		draw_circle(p, 2.0, color)

func _draw_missile_launcher(style):
	var params = _get_panel_style_params(style)
	var color = ThemeManager.proj_missile_glow
	var size = 28.0
	var rect = Rect2(-size/2, -size/2, size, size)
	if not params.hollow:
		draw_rect(rect, Color.BLACK, true)
	draw_rect(rect, color, false, params.outline_width)
	for x in [-1, 1]:
		for y in [-1, 1]:
			draw_circle(Vector2(x, y) * 6.0, 3.0, color)

func _draw_health_kit(style):
	var params = _get_panel_style_params(style)
	var color = ThemeManager.pickup_health
	var size = 20.0
	var rect = Rect2(-size/2, -size/2, size, size)
	if not params.hollow:
		draw_rect(rect, Color.BLACK, true)
	draw_rect(rect, color, false, params.outline_width)
	draw_line(Vector2(-5, 0), Vector2(5, 0), Color.WHITE, 2.0)
	draw_line(Vector2(0, -5), Vector2(0, 5), Color.WHITE, 2.0)
