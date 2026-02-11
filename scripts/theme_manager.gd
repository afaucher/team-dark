extends Node

# --- Core Color Palette ---
# Unified Neon Vector / Synthwave identity

@export_group("Player Palette")
@export var player_primary: Color = Color("#00FFFF")   # Electric Cyan
@export var player_secondary: Color = Color("#008B8B") # Dark Cyan
@export var player_core: Color = Color(2.0, 2.0, 2.0)  # HDR White core

@export_group("Enemy Palette")
@export var enemy_tier_1: Color = Color("#FF00FF")     # Hot Magenta (Standard)
@export var enemy_tier_2: Color = Color("#FF2D55")     # Radical Red (Advanced)
@export var enemy_tier_3: Color = Color("#7000FF")     # Deep Violet (Elite/Boss)
@export var enemy_kamikaze: Color = Color("#FFAA00")   # Warning Orange
@export var enemy_shield: Color = Color("#00AACC")     # Energy Blue

@export_group("Environment Palette")
@export var bg_void: Color = Color("#050510")          # Deep Navy/Black
@export var grid_main: Color = Color("#7000FF", 0.2)   # Violet Grid lines
@export var alert_red: Color = Color("#FF0000")        # Danger
@export var success_green: Color = Color("#00FF00")    # Valid

@export_group("Pickup Palette")
@export var pickup_weapon: Color = Color("#00FFFF")    # Cyan
@export var pickup_health: Color = Color("#FF0000")    # Red
@export var pickup_gem: Color = Color("#FF00FF")       # Magenta
@export var pickup_utility: Color = Color("#FF9A00")   # Orange

@export_group("Projectile Palette")
@export var proj_pellet_glow: Color = Color(0.0, 1.5, 1.5) # HDR Cyan
@export var proj_grenade_glow: Color = Color(1.5, 0.5, 0.0) # HDR Orange
@export var proj_missile_glow: Color = Color(0.5, 1.5, 0.2) # HDR Lime

@export_group("Effect Palette")
@export var impact_sparks: Color = Color(1.0, 1.0, 1.0) # White
@export var impact_distortion: Color = Color(0.3, 0.5, 1.0, 0.5) # Blue tint

@export_group("Global Rendering")
@export var bloom_intensity: float = 1.2
@export var hdr_threshold: float = 1.0

# --- Helper Methods ---
func get_enemy_color(tier: int, type: String = "standard") -> Color:
	if type == "kamikaze": return enemy_kamikaze
	match tier:
		1: return enemy_tier_1
		2: return enemy_tier_2
		3: return enemy_tier_3
		_: return enemy_tier_1

func get_pickup_color(type: String) -> Color:
	match type.to_lower():
		"weapon": return pickup_weapon
		"health": return pickup_health
		"gem": return pickup_gem
		"utility": return pickup_utility
		_: return Color.WHITE

# --- HUD Styles ---
enum HUDStyle { SEGMENTED, MINIMALIST, TACTICAL, COMBAT }
@export var current_hud_style: HUDStyle = HUDStyle.SEGMENTED

# Dynamic variation (Experimentation)
func apply_theme_preset(mode: String):
	match mode:
		"Cyberpunk":
			player_primary = Color("#00FF9F") # Neo Mint
			enemy_tier_1 = Color("#FF2D55")   # Red/Pink
			bg_void = Color("#0A0010")        # Dark Purple
			current_hud_style = HUDStyle.MINIMALIST
		"Retro":
			player_primary = Color("#00FFFF") # Classic Cyan
			enemy_tier_1 = Color("#FF00FF")   # Classic Magenta
			bg_void = Color("#000000")        # Pure Black
			current_hud_style = HUDStyle.SEGMENTED
		"HighContrast":
			player_primary = Color("#FFFFFF") # White
			enemy_tier_1 = Color("#FFFF00")   # Yellow
			bg_void = Color("#000000")
			current_hud_style = HUDStyle.TACTICAL
