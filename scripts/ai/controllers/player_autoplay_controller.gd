extends "res://scripts/ai/controllers/ai_controller.gd"

# Nodes
var beehave_tree: Node
var blackboard: Node

func _ready():
	super._ready()
	_setup_beehave()

func _setup_beehave():
	# Load Beehave classes at runtime
	var BlackboardClass = load("res://addons/beehave/blackboard.gd")
	var BeehaveTreeClass = load("res://addons/beehave/nodes/beehave_tree.gd")
	var SelectorCompositeClass = load("res://addons/beehave/nodes/composites/selector.gd")
	var SequenceCompositeClass = load("res://addons/beehave/nodes/composites/sequence.gd")
	
	if not BlackboardClass or not BeehaveTreeClass:
		push_error("[AI] Failed to load Beehave classes!")
		return
	
	blackboard = BlackboardClass.new()
	
	beehave_tree = BeehaveTreeClass.new()
	beehave_tree.blackboard = blackboard
	add_child(beehave_tree)
	
	# Set the actor to the player AFTER adding to scene tree
	var player = get_parent()
	beehave_tree.actor = player
	
	# Behavior Tree Structure:
	# Selector (tries children until one succeeds)
	#   Sequence (Combat) - attack nearby enemies
	#     AttackNearestEnemyAction
	#   Sequence (Mission) - find and navigate to objectives
	#     FindMissionTargetAction
	#     NavigateToTargetAction
	
	var root_selector = SelectorCompositeClass.new()
	root_selector.name = "RootSelector"
	beehave_tree.add_child(root_selector)
	
	# Combat Branch
	var combat_seq = SequenceCompositeClass.new()
	combat_seq.name = "CombatSequence"
	root_selector.add_child(combat_seq)
	
	var attack_node = load("res://scripts/ai/nodes/actions/attack_nearest_enemy.gd").new()
	attack_node.name = "AttackNearestEnemy"
	combat_seq.add_child(attack_node)
	
	# Mission Branch
	var mission_seq = SequenceCompositeClass.new()
	mission_seq.name = "MissionSequence"
	root_selector.add_child(mission_seq)
	
	var find_target_node = load("res://scripts/ai/nodes/actions/find_mission_target.gd").new()
	find_target_node.name = "FindMissionTarget"
	mission_seq.add_child(find_target_node)
	
	var navigate_node = load("res://scripts/ai/nodes/actions/navigate_to_target.gd").new()
	navigate_node.name = "NavigateToTarget"
	mission_seq.add_child(navigate_node)
	
	beehave_tree.enabled = true

func update_actions(delta: float):
	# Don't reset move/aim vectors - Beehave tree sets them in _physics_process
	# and we need those values to persist when player._gather_inputs() reads them.
	# Only reset "just pressed" booleans that should be single-frame
	fire_all_just = false
	for i in range(3):
		fire_just_pressed[i] = false
