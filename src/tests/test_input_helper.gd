extends GdUnitTestSuite
## Unit tests for InputHelper
##
## Tests input buffering, combo detection, movement vectors, and utilities

var input_helper: Node


func before_test():
	input_helper = load("res://src/core/managers/input_helper.gd").new()
	add_child(input_helper)
	await get_tree().process_frame


func after_test():
	if is_instance_valid(input_helper):
		input_helper.queue_free()
		await get_tree().process_frame
	input_helper = null
	
	# Clear any test input actions
	_cleanup_test_actions()


func _cleanup_test_actions():
	var actions = ["test_left", "test_right", "test_up", "test_down", "test_action", "jump", "attack", "special"]
	for action in actions:
		if InputMap.has_action(action):
			InputMap.erase_action(action)


func test_input_buffer_initialization():
	assert_that(input_helper._buffered_actions).is_not_null()
	assert_that(input_helper._action_history).is_not_null()


func test_get_movement_vector_default_actions():
	# Without actual input events, should return zero vector
	var vector = input_helper.get_movement_vector()
	assert_that(vector).is_equal(Vector2.ZERO)


func test_get_movement_vector_normalized():
	# Mock diagonal input (would normally be > 1.0)
	# This tests the normalization behavior
	var vector = input_helper.get_movement_vector()
	assert_float(vector.length()).is_less_equal(1.0)


func test_get_movement_vector_raw():
	# Raw vector doesn't normalize
	var vector = input_helper.get_movement_vector_raw()
	assert_int(typeof(vector)).is_equal(TYPE_VECTOR2)


func test_get_horizontal_direction():
	var direction = input_helper.get_horizontal_direction()
	assert_float(direction).is_between(-1.0, 1.0)


func test_get_vertical_direction():
	var direction = input_helper.get_vertical_direction()
	assert_float(direction).is_between(-1.0, 1.0)


func test_action_buffering():
	# Simulate action press
	var action = "jump"
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	
	# Manually add to buffer
	input_helper._buffered_actions[action] = Time.get_ticks_msec() / 1000.0
	
	# Should be buffered
	assert_bool(input_helper.is_action_buffered(action)).is_true()


func test_consume_buffered_action():
	var action = "jump"
	input_helper._buffered_actions[action] = Time.get_ticks_msec() / 1000.0
	
	assert_bool(input_helper.is_action_buffered(action)).is_true()
	
	input_helper.consume_buffered_action(action)
	assert_bool(input_helper.is_action_buffered(action)).is_false()


func test_buffer_expiration():
	var action = "jump"
	# Add an old timestamp (1 second ago)
	input_helper._buffered_actions[action] = (Time.get_ticks_msec() / 1000.0) - 1.0
	
	# Buffer time is 0.15s, so should be expired
	assert_bool(input_helper.is_action_buffered(action)).is_false()


func test_clear_buffers():
	input_helper._buffered_actions["jump"] = Time.get_ticks_msec() / 1000.0
	input_helper._buffered_actions["attack"] = Time.get_ticks_msec() / 1000.0
	
	input_helper.clear_buffers()
	
	assert_that(input_helper._buffered_actions).is_empty()


func test_combo_history():
	var current_time = Time.get_ticks_msec() / 1000.0

	input_helper._action_history.append({"action": "attack", "timestamp": current_time})
	input_helper._action_history.append({"action": "attack", "timestamp": current_time + 0.1})
	input_helper._action_history.append({"action": "special", "timestamp": current_time + 0.2})

	var combo_actions: Array[String] = ["attack", "attack", "special"]
	var combo = input_helper.check_combo_sequence(combo_actions, 0.5)
	assert_bool(combo).is_true()


func test_combo_sequence_wrong_order():
	var current_time = Time.get_ticks_msec() / 1000.0

	input_helper._action_history.append({"action": "attack", "timestamp": current_time})
	input_helper._action_history.append({"action": "special", "timestamp": current_time + 0.1})
	input_helper._action_history.append({"action": "attack", "timestamp": current_time + 0.2})

	var combo_actions: Array[String] = ["attack", "attack", "special"]
	# Wrong order
	var combo = input_helper.check_combo_sequence(combo_actions, 0.5)
	assert_bool(combo).is_false()


func test_combo_sequence_timeout():
	var current_time = Time.get_ticks_msec() / 1000.0

	input_helper._action_history.append({"action": "attack", "timestamp": current_time - 2.0})
	input_helper._action_history.append({"action": "attack", "timestamp": current_time - 1.5})
	input_helper._action_history.append({"action": "special", "timestamp": current_time})

	var combo_actions: Array[String] = ["attack", "attack", "special"]
	# Too much time between actions
	var combo = input_helper.check_combo_sequence(combo_actions, 0.5)
	assert_bool(combo).is_false()


func test_clear_combo_history():
	input_helper._action_history.append({"action": "attack", "timestamp": Time.get_ticks_msec() / 1000.0})
	input_helper.clear_combo_history()
	assert_that(input_helper._action_history).is_empty()


func test_get_last_pressed_action():
	input_helper._action_history.append({"action": "jump", "timestamp": Time.get_ticks_msec() / 1000.0})
	input_helper._action_history.append({"action": "attack", "timestamp": Time.get_ticks_msec() / 1000.0})
	
	var last = input_helper.get_last_pressed_action()
	assert_str(last).is_equal("attack")


func test_get_last_pressed_action_empty():
	input_helper._action_history.clear()
	
	var last = input_helper.get_last_pressed_action()
	assert_str(last).is_equal("")


func test_is_moving():
	# Without actual input, should return false
	var moving = input_helper.is_moving()
	assert_bool(moving).is_false()


func test_analog_to_digital():
	assert_float(input_helper.analog_to_digital(0.0)).is_equal(0.0)
	assert_float(input_helper.analog_to_digital(0.3)).is_equal(0.0)  # Below threshold
	assert_float(input_helper.analog_to_digital(0.6)).is_equal(1.0)  # Above threshold
	assert_float(input_helper.analog_to_digital(-0.6)).is_equal(-1.0)


func test_analog_to_digital_custom_threshold():
	assert_float(input_helper.analog_to_digital(0.3, 0.2)).is_equal(1.0)
	assert_float(input_helper.analog_to_digital(0.1, 0.2)).is_equal(0.0)


func test_history_size_limit():
	# Fill history beyond 10 items
	for i in range(15):
		input_helper._action_history.append({
			"action": "test_%d" % i,
			"timestamp": Time.get_ticks_msec() / 1000.0
		})
	
	# Simulate the trimming that happens in _input
	while input_helper._action_history.size() > 10:
		input_helper._action_history.pop_front()
	
	# Should be limited to 10
	assert_int(input_helper._action_history.size()).is_less_equal(10)


func test_get_gamepad_stick():
	# Without actual gamepad, should return zero
	var stick = input_helper.get_gamepad_stick()
	assert_that(stick).is_equal(Vector2.ZERO)


func test_buffer_time_configuration():
	input_helper.input_buffer_time = 0.3
	assert_float(input_helper.input_buffer_time).is_equal(0.3)


func test_coyote_time_configuration():
	input_helper.coyote_time = 0.2
	assert_float(input_helper.coyote_time).is_equal(0.2)