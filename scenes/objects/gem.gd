class_name Gem
extends Area2D

signal collected(gem_type)

@export var gem_type: String = "Red"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("players"):
		# Server authoritative collection
		if multiplayer.is_server():
			# Notify game state
			_collect(body)

func _collect(player):
	print("Gem collected by ", player.name)
	queue_free()
	# TODO: Emit global signal or RPC to update UI/GameState
