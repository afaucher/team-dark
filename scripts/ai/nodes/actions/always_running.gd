extends ActionLeaf

## AlwaysRunningAction
## Returns RUNNING every tick. Useful for keeping Parallel branches alive.

func tick(actor: Node, blackboard: Blackboard) -> int:
	return RUNNING
