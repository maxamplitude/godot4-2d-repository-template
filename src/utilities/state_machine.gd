# src/utilities/state_machine.gd
extends Node
class_name StateMachine

class State:
	extends Node

	var state_machine: StateMachine

	func enter() -> void:
		pass

	func exit() -> void:
		pass

var current_state: State
var states: Dictionary[String, State] = {}

func _ready():
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self

	if get_child_count() > 0:
		var first = get_child(0)
		if first is State:
			change_state(first.name)

func change_state(state_name: String) -> void:
	var next_state := states.get(state_name, null)
	if not next_state:
		push_warning("StateMachine: State '%s' not registered" % state_name)
		return

	if current_state:
		current_state.exit()

	current_state = next_state
	current_state.enter()
