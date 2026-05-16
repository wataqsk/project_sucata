# This script holds reference to whichever state is currently active.
# It listens to every state's signal and performs the swap when one fires.
# States never talk to each other, they only talk to StateMachine through that signal.

class_name StateMachine extends Node

# Lets pick the starting state directly in the Inspector.
@export var initial_state: State = null

# Holds the exported choice as the current active state from frame one.
# If no child node selected, it holds the first child node instead.
@onready var state: State = (func get_initial_state() -> State:
	return initial_state if initial_state != null else get_child(0)
).call()


# Scans all State classes and connects their finished signals.
# Adding a new state node to the tree gets it wired automatically.
func _ready() -> void:
	for state_node: State in find_children("*", "State"):
		state_node.finished.connect(_transition_to_next_state)

	# Pauses until the Player node is fully ready.
	# Without the await, It might cause null errors.
	await owner.ready
	state.enter("")

# Forwards input only to the active state.
func _unhandled_input(event: InputEvent) -> void:
	state.handle_input(event)
	
func _process(delta: float) -> void:
	state.update(delta)
	
func _physics_process(delta: float) -> void:
	state.physics_update(delta)
	DebugDraw2D.set_text("State", state.name)


func _transition_to_next_state(target_state_path: String, data: Dictionary = {}) -> void:
	#  Prints an error and aborts if the state doesn't exist as a child.
	if not has_node(target_state_path):
		printerr(owner.name + ": Trying to transition to state " + target_state_path + " but it does not exist.")
		return

	# Saves the current state's name before switching.
	# Clean up the current state before switch.
	# Swaps the reference and activates the new state.
	var previous_state_path := state.name
	state.exit()
	state = get_node(target_state_path)
	state.enter(previous_state_path, data)
