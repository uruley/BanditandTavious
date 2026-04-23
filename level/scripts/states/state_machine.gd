class_name StateMachine
extends Node

## Emitted when transitioning to a new state.
signal transitioned(state_name: String)

## Path to the initial active state. We export it to be able to pick the initial state in the inspector.
@export var initial_state: NodePath

## The current active state. At the start of the game, we get the `initial_state`.
@onready var state: State = get_node(initial_state)

var is_ready := false

@onready var player: BachtaviousPlayer = get_parent() as BachtaviousPlayer

func _ready() -> void:
	print("DEBUG: StateMachine _ready started")
	if initial_state.is_empty() or not has_node(initial_state):
		push_error("StateMachine: initial_state is invalid!")
		return
		
	state = get_node(initial_state)
	
	# The state machine assigns itself to the State objects' state_machine property.
	for child in get_children():
		if child is State:
			child.state_machine = self
	
	is_ready = true
	if state:
		print("DEBUG: StateMachine entering initial state: ", state.name)
		state.enter()
	else:
		push_error("StateMachine: state is null!")

# The state machine delegates the unhandled input to the active state.
func _unhandled_input(event: InputEvent) -> void:
	if not is_ready or not player.is_multiplayer_authority() or player._is_parkouring: return
	if state: state.handle_input(event)

# The state machine delegates the process tick to the active state.
func _process(delta: float) -> void:
	if not is_ready or not player.is_multiplayer_authority() or player._is_parkouring: return
	if state: state.update(delta)

# The state machine delegates the physics process tick to the active state.
func _physics_process(delta: float) -> void:
	if not is_ready:
		return
	if not player.is_multiplayer_authority():
		return
	if player._is_parkouring:
		return
	if state:
		state.physics_update(delta)

## This function calls the current state's exit() function, then changes the active state,
## and calls its enter() function.
## It optionally takes a `msg` dictionary to pass to the next state's enter() function.
func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	if not has_node(target_state_name):
		push_error("State machine: Target state %s does not exist." % target_state_name)
		return

	state.exit()
	state = get_node(target_state_name)
	state.enter(msg)
	emit_signal("transitioned", state.name)
