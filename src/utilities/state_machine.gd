# src/utilities/state_machine.gd
class_name StateMachine extends Node

var current_state: State
var states := {}

func _ready():
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self
    
	if get_child_count() > 0:
		change_state(get_child(0).name)

func change_state(state_name: String):
	if current_state:
		current_state.exit()
	current_state = states[state_name]
	current_state.enter()
