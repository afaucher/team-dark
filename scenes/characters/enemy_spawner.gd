class_name EnemySpawner
extends Node2D

@export var enemy_scene: PackedScene
@export var cluster_size: int = 3
@export var spawn_radius: float = 100.0

func spawn():
	if not multiplayer.is_server():
		return
		
	for i in range(cluster_size):
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(0, spawn_radius)
		var enemy = enemy_scene.instantiate()
		enemy.global_position = global_position + offset
		get_parent().add_child(enemy)
