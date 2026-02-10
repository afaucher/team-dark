extends "res://addons/beehave/nodes/leaves/action.gd"

## PatrolRandom Action
## Picks a random point within a radius and moves towards it.

@export var patrol_radius: float = 1000.0
@export var arrival_tolerance: float = 20.0

var target_pos: Vector2 = Vector2.ZERO
var has_target: bool = false

func tick(actor: Node, blackboard: Blackboard) -> int:
	if not has_target:
		# Pick a random point around current position
		var angle = randf() * TAU
		var dist = randf() * patrol_radius
		target_pos = actor.global_position + Vector2(cos(angle), sin(angle)) * dist
		has_target = true
		
	var to_target = target_pos - actor.global_position
	if to_target.length() < arrival_tolerance:
		has_target = false
		return SUCCESS
		
	var dir = to_target.normalized()
	if "velocity" in actor and "speed" in actor:
		# Use lower speed for patrolling
		actor.velocity = dir * (actor.speed * 0.5)
		actor.rotation = lerp_angle(actor.rotation, dir.angle(), 0.05)
		
	return RUNNING
