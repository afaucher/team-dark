extends ActionLeaf

## MaintainFlock
## Basic Boids behavior to keep swarm enemies together.

@export var flock_radius: float = 400.0
@export var separation_weight: float = 1.5
@export var cohesion_weight: float = 1.0
@export var alignment_weight: float = 0.5

func tick(actor: Node, blackboard: Blackboard) -> int:
	if not actor is CharacterBody2D:
		return FAILURE
		
	var neighbors = get_tree().get_nodes_in_group("swarm")
	if neighbors.is_empty():
		return FAILURE
		
	var separation = Vector2.ZERO
	var cohesion = Vector2.ZERO
	var alignment = Vector2.ZERO
	var count = 0
	
	for n in neighbors:
		if n == actor or not is_instance_valid(n):
			continue
			
		var dist = actor.global_position.distance_to(n.global_position)
		if dist < flock_radius:
			# Separation
			if dist > 0:
				separation += (actor.global_position - n.global_position).normalized() / dist
			
			# Cohesion
			cohesion += n.global_position
			
			# Alignment
			if "velocity" in n:
				alignment += n.velocity
				
			count += 1
			
	if count > 0:
		separation = (separation / count) * separation_weight * 5000.0
		cohesion = ((cohesion / count) - actor.global_position) * cohesion_weight
		alignment = (alignment / count) * alignment_weight
		
		# Combine and apply to actor's velocity (steering)
		var flock_force = separation + cohesion + alignment
		actor.velocity = actor.velocity.move_toward(actor.velocity + flock_force, actor.speed * 0.5)
		
	return SUCCESS
