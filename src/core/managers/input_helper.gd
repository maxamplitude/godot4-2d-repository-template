extends Node
class_name InputHelper

## Helper functions for common input patterns
##
## Provides utility methods for getting input vectors, buffering,
## and other common input-related tasks.

## Input buffer duration in seconds
@export var input_buffer_time: float = 0.15

## Coyote time duration in seconds (for jump buffering)
@export var coyote_time: float = 0.1

var _buffered_actions: Dictionary = {}  # action_name -> timestamp
var _action_history: Array[Dictionary] = []  # For combo detection


func _ready() -> void:
	set_process_input(true)


func _input(event: InputEvent) -> void:
	# Record action presses for buffering
	if event.is_pressed():
		for action in InputMap.get_actions():
			if event.is_action_pressed(action):
				_buffered_actions[action] = Time.get_ticks_msec() / 1000.0
				
				# Record for combo detection
				_action_history.append({
					"action": action,
					"timestamp": Time.get_ticks_msec() / 1000.0
				})
				
				# Keep history size manageable
				if _action_history.size() > 10:
					_action_history.pop_front()


## Get normalized movement vector from directional inputs
## Returns Vector2 with magnitude 0-1
func get_movement_vector(
	left_action: String = "move_left",
	right_action: String = "move_right",
	up_action: String = "move_up",
	down_action: String = "move_down"
) -> Vector2:
	var vector = Vector2.ZERO
	
	vector.x = Input.get_axis(left_action, right_action)
	vector.y = Input.get_axis(up_action, down_action)
	
	return vector.normalized() if vector.length() > 1.0 else vector


## Get movement vector with separate strength for horizontal and vertical
## Useful for games where you want full diagonal speed
func get_movement_vector_raw(
	left_action: String = "move_left",
	right_action: String = "move_right",
	up_action: String = "move_up",
	down_action: String = "move_down"
) -> Vector2:
	var vector = Vector2.ZERO
	
	vector.x = Input.get_axis(left_action, right_action)
	vector.y = Input.get_axis(up_action, down_action)
	
	return vector


## Check if an action was pressed recently (within buffer time)
## Useful for jump buffering, attack buffering, etc.
func is_action_buffered(action: String) -> bool:
	if action not in _buffered_actions:
		return false
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var buffer_age = current_time - _buffered_actions[action]
	
	return buffer_age <= input_buffer_time


## Consume a buffered action (removes it from buffer)
## Use this when you've acted on the buffered input
func consume_buffered_action(action: String) -> void:
	_buffered_actions.erase(action)


## Get the direction the player is pressing (returns -1, 0, or 1)
## Useful for 2D platformers and side-scrollers
func get_horizontal_direction(
	left_action: String = "move_left",
	right_action: String = "move_right"
) -> float:
	return Input.get_axis(left_action, right_action)


## Get vertical direction
func get_vertical_direction(
	up_action: String = "move_up",
	down_action: String = "move_down"
) -> float:
	return Input.get_axis(up_action, down_action)


## Check if a combo sequence was performed
## Example: check_combo_sequence(["attack", "attack", "special"], 0.5)
func check_combo_sequence(actions: Array[String], max_time_between: float) -> bool:
	if actions.is_empty() or _action_history.is_empty():
		return false
	
	if actions.size() > _action_history.size():
		return false
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var match_index = 0
	
	# Search backwards through history
	for i in range(_action_history.size() - 1, -1, -1):
		var history_item = _action_history[i]
		
		# Check if this action is too old
		if current_time - history_item["timestamp"] > max_time_between * actions.size():
			break
		
		# Check if it matches the expected action
		if history_item["action"] == actions[actions.size() - 1 - match_index]:
			match_index += 1
			
			if match_index == actions.size():
				return true
	
	return false


## Clear all buffered inputs
func clear_buffers() -> void:
	_buffered_actions.clear()


## Clear combo history
func clear_combo_history() -> void:
	_action_history.clear()


## Get the most recent action pressed
func get_last_pressed_action() -> String:
	if _action_history.is_empty():
		return ""
	
	return _action_history.back()["action"]


## Check if any movement input is currently pressed
func is_moving(
	left_action: String = "move_left",
	right_action: String = "move_right",
	up_action: String = "move_up",
	down_action: String = "move_down"
) -> bool:
	return Input.is_action_pressed(left_action) or \
		   Input.is_action_pressed(right_action) or \
		   Input.is_action_pressed(up_action) or \
		   Input.is_action_pressed(down_action)


## Get analog stick value for gamepad (returns Vector2 from -1 to 1)
func get_gamepad_stick(stick: JoyAxis = JOY_AXIS_LEFT_X) -> Vector2:
	var x = Input.get_joy_axis(0, stick)
	var y = Input.get_joy_axis(0, stick + 1)
	
	# Apply deadzone
	var deadzone = 0.15
	if abs(x) < deadzone:
		x = 0.0
	if abs(y) < deadzone:
		y = 0.0
	
	return Vector2(x, y)


## Convert analog input to digital (returns -1, 0, or 1)
func analog_to_digital(value: float, threshold: float = 0.5) -> float:
	if abs(value) < threshold:
		return 0.0
	return sign(value)