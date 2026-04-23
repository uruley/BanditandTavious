class_name PlayerState
extends State

## Typed reference to the player node.
var player: BachtaviousPlayer

func _ready() -> void:
	var sm = get_parent()
	player = sm.get_parent() as BachtaviousPlayer
	
	if not player:
		push_error("PlayerState: Player reference is null. Make sure the StateMachine is a direct child of the Player.")
