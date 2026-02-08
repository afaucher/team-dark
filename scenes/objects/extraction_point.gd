class_name ExtractionPoint
extends Area2D

var active: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func activate():
	active = true
	visible = true
	# Visual effect for activation

func _on_body_entered(body):
	if active and body.is_in_group("players"):
		_extract(body)

func _extract(player):
	print("Player extracted: ", player.name)
	# Trigger win condition or remove player from danger
