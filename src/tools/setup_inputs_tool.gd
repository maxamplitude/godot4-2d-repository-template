@tool
extends Node
## Input Map Setup Tool
##
## Instructions:
## 1. Open any scene (even main_menu.tscn)
## 2. Add a Node to the scene
## 3. Attach this script to that node
## 4. In the Inspector, check the "Setup Input Map" checkbox
## 5. Check Output panel for confirmation
## 6. Restart Godot
## 7. Delete this node after setup is complete

@export var setup_input_map: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			_setup_inputs()
			setup_input_map = false  # Reset checkbox


func _setup_inputs() -> void:
	print("========================================")
	print("Setting up Input Map for Godot Template")
	print("========================================")
	
	_setup_system_inputs()
	_setup_movement_inputs()
	_setup_action_inputs()
	
	# Save project settings
	var err = ProjectSettings.save()
	if err == OK:
		print("\n✓ Saved changes to project.godot")
		print("========================================")
		print("✓ Input Map setup complete!")
		print("RESTART GODOT to see changes in Input Map.")
		print("========================================")
	else:
		print("\n✗ ERROR: Failed to save project settings!")
		print("Error code: ", err)


## System inputs (required for GameManager)
func _setup_system_inputs() -> void:
	print("\n--- Setting up System Inputs ---")
	
	# Pause
	_add_action("pause")
	_add_key("pause", KEY_ESCAPE)
	_add_key("pause", KEY_P)
	_add_joypad_button("pause", JOY_BUTTON_START)
	print("✓ pause")
	
	# Toggle fullscreen
	_add_action("toggle_fullscreen")
	_add_key("toggle_fullscreen", KEY_F11)
	print("✓ toggle_fullscreen")
	
	# Toggle debug
	_add_action("toggle_debug")
	_add_key("toggle_debug", KEY_F3)
	print("✓ toggle_debug")
	
	# Screenshot (bonus)
	_add_action("screenshot")
	_add_key("screenshot", KEY_F12)
	print("✓ screenshot")


## Movement inputs
func _setup_movement_inputs() -> void:
	print("\n--- Setting up Movement Inputs ---")
	
	# Move left
	_add_action("move_left")
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_joypad_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joypad_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	print("✓ move_left")
	
	# Move right
	_add_action("move_right")
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_joypad_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joypad_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	print("✓ move_right")
	
	# Move up
	_add_action("move_up")
	_add_key("move_up", KEY_W)
	_add_key("move_up", KEY_UP)
	_add_joypad_button("move_up", JOY_BUTTON_DPAD_UP)
	_add_joypad_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	print("✓ move_up")
	
	# Move down
	_add_action("move_down")
	_add_key("move_down", KEY_S)
	_add_key("move_down", KEY_DOWN)
	_add_joypad_button("move_down", JOY_BUTTON_DPAD_DOWN)
	_add_joypad_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	print("✓ move_down")


## Action inputs (gameplay)
func _setup_action_inputs() -> void:
	print("\n--- Setting up Action Inputs ---")
	
	# Jump
	_add_action("jump")
	_add_key("jump", KEY_SPACE)
	_add_key("jump", KEY_W)
	_add_joypad_button("jump", JOY_BUTTON_A)
	print("✓ jump")
	
	# Attack
	_add_action("attack")
	_add_key("attack", KEY_J)
	_add_key("attack", KEY_Z)
	_add_mouse_button("attack", MOUSE_BUTTON_LEFT)
	_add_joypad_button("attack", JOY_BUTTON_X)
	print("✓ attack")
	
	# Special
	_add_action("special")
	_add_key("special", KEY_K)
	_add_key("special", KEY_X)
	_add_mouse_button("special", MOUSE_BUTTON_RIGHT)
	_add_joypad_button("special", JOY_BUTTON_B)
	print("✓ special")
	
	# Dodge
	_add_action("dodge")
	_add_key("dodge", KEY_SHIFT)
	_add_joypad_button("dodge", JOY_BUTTON_Y)
	print("✓ dodge")
	
	# Interact
	_add_action("interact")
	_add_key("interact", KEY_E)
	_add_joypad_button("interact", JOY_BUTTON_A)
	print("✓ interact")


## Helper functions
func _add_action(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		# Also add to project settings
		ProjectSettings.set_setting("input/" + action_name, {
			"deadzone": 0.5,
			"events": []
		})


func _add_key(action: String, keycode: Key) -> void:
	var event = InputEventKey.new()
	event.keycode = keycode
	
	if not _event_exists(action, event):
		InputMap.action_add_event(action, event)
		_add_event_to_project_settings(action, event)


func _add_mouse_button(action: String, button: MouseButton) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = button
	
	if not _event_exists(action, event):
		InputMap.action_add_event(action, event)
		_add_event_to_project_settings(action, event)


func _add_joypad_button(action: String, button: JoyButton) -> void:
	var event = InputEventJoypadButton.new()
	event.button_index = button
	
	if not _event_exists(action, event):
		InputMap.action_add_event(action, event)
		_add_event_to_project_settings(action, event)


func _add_joypad_axis(action: String, axis: JoyAxis, value: float) -> void:
	var event = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	
	if not _event_exists(action, event):
		InputMap.action_add_event(action, event)
		_add_event_to_project_settings(action, event)


func _add_event_to_project_settings(action: String, event: InputEvent) -> void:
	var setting_name = "input/" + action
	if not ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, {
			"deadzone": 0.5,
			"events": []
		})
	
	var action_dict = ProjectSettings.get_setting(setting_name)
	if not action_dict.has("events"):
		action_dict["events"] = []
	
	action_dict["events"].append(event)
	ProjectSettings.set_setting(setting_name, action_dict)


func _event_exists(action: String, new_event: InputEvent) -> bool:
	var events = InputMap.action_get_events(action)
	for event in events:
		if _events_match(event, new_event):
			return true
	return false


func _events_match(a: InputEvent, b: InputEvent) -> bool:
	if a.get_class() != b.get_class():
		return false
	
	if a is InputEventKey and b is InputEventKey:
		return a.keycode == b.keycode
	elif a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	elif a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	elif a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and a.axis_value == b.axis_value
	
	return false