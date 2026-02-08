extends Node2D

@export var weapon_name: String = "Health Kit"
@export var is_passive: bool = true

func trigger(just_pressed: bool, is_held: bool):
	if just_pressed:
		var parent = get_parent() # Mount
		if parent:
			var player = parent.get_parent() # Player
			if player and player.has_method("heal"):
				var max_hp = player.max_hp if "max_hp" in player else 100.0
				player.heal(max_hp * 0.25)
				
				# Remove myself from mount
				if player.has_method("equip_weapon"):
					# Find our mount index
					var idx = -1
					if "mounts" in player:
						for i in range(player.mounts.size()):
							if player.mounts[i] == parent:
								idx = i
								break
					
					if idx != -1:
						player.equip_weapon.rpc(idx, "")

func _draw():
	# Neon Vector Health Kit Style
	var size = 16.0
	var color = Color(1.0, 0.0, 0.0, 1.0) # Red
	
	# Box
	var rect = Rect2(-size/2, -size/2, size, size)
	draw_rect(rect, color * Color(1, 1, 1, 0.3), false, 4.0)
	draw_rect(rect, Color.BLACK, true)
	draw_rect(rect, color, false, 2.0)
	
	# Plus sign
	draw_line(Vector2(-4, 0), Vector2(4, 0), Color.WHITE, 2.0)
	draw_line(Vector2(0, -4), Vector2(0, 4), Color.WHITE, 2.0)
