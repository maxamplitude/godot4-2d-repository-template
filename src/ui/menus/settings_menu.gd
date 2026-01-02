extends Control
## Settings menu
##
## Allows configuration of audio, display, and controls

@onready var back_button: Button = %BackButton
@onready var tab_container: TabContainer = %TabContainer

# Audio tab
@onready var master_slider: AudioSlider = %MasterSlider
@onready var music_slider: AudioSlider = %MusicSlider
@onready var sfx_slider: AudioSlider = %SFXSlider
@onready var ui_slider: AudioSlider = %UISlider

# Display tab
@onready var window_mode_option: OptionButton = %WindowModeOption
@onready var vsync_option: OptionButton = %VsyncOption
@onready var resolution_option: OptionButton = %ResolutionOption

# Controls tab
@onready var controls_container: VBoxContainer = %ControlsContainer


func _ready() -> void:
	# Set process mode to always so it works when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	
	# Setup display options
	_setup_display_options()
	
	# Setup controls list
	_setup_controls_list()
	
	# Focus back button
	back_button.grab_focus()


func _setup_display_options() -> void:
	# Window mode
	window_mode_option.clear()
	window_mode_option.add_item("Windowed", 0)
	window_mode_option.add_item("Fullscreen", 1)
	window_mode_option.add_item("Borderless", 2)
	
	var current_window_mode = SettingsManager.get_setting("display", "window_mode", 0)
	window_mode_option.selected = current_window_mode
	window_mode_option.item_selected.connect(_on_window_mode_changed)
	
	# VSync
	vsync_option.clear()
	vsync_option.add_item("Disabled", 0)
	vsync_option.add_item("Enabled", 1)
	vsync_option.add_item("Adaptive", 2)
	
	var current_vsync = SettingsManager.get_setting("display", "vsync_mode", 1)
	vsync_option.selected = current_vsync
	vsync_option.item_selected.connect(_on_vsync_changed)
	
	# Resolution (only show in windowed mode)
	resolution_option.clear()
	resolution_option.add_item("1280x720", 0)
	resolution_option.add_item("1920x1080", 1)
	resolution_option.add_item("2560x1440", 2)
	resolution_option.add_item("3840x2160", 3)
	
	var current_width = SettingsManager.get_setting("display", "resolution_width", 1920)
	match current_width:
		1280: resolution_option.selected = 0
		1920: resolution_option.selected = 1
		2560: resolution_option.selected = 2
		3840: resolution_option.selected = 3
	
	resolution_option.item_selected.connect(_on_resolution_changed)


func _setup_controls_list() -> void:
	# Clear existing controls
	for child in controls_container.get_children():
		child.queue_free()
	
	# Add control remapping UI for common actions
	var actions = ["move_left", "move_right", "move_up", "move_down", "jump", "attack", "pause"]
	
	for action in actions:
		if InputMap.has_action(action):
			var hbox = HBoxContainer.new()
			
			var label = Label.new()
			label.text = action.capitalize() + ":"
			label.custom_minimum_size = Vector2(150, 0)
			hbox.add_child(label)
			
			var current_binding = SettingsManager.get_input_binding(action)
			var binding_label = Label.new()
			binding_label.text = _get_binding_text(current_binding)
			binding_label.custom_minimum_size = Vector2(100, 0)
			hbox.add_child(binding_label)
			
			var rebind_button = Button.new()
			rebind_button.text = "Rebind"
			rebind_button.pressed.connect(_on_rebind_pressed.bind(action, binding_label))
			hbox.add_child(rebind_button)
			
			var reset_button = Button.new()
			reset_button.text = "Reset"
			reset_button.pressed.connect(_on_reset_binding_pressed.bind(action, binding_label))
			hbox.add_child(reset_button)
			
			controls_container.add_child(hbox)


func _get_binding_text(event: InputEvent) -> String:
	if event == null:
		return "None"
	
	if event is InputEventKey:
		return OS.get_keycode_string(event.keycode)
	elif event is InputEventMouseButton:
		return "Mouse " + str(event.button_index)
	elif event is InputEventJoypadButton:
		return "Joy " + str(event.button_index)
	
	return "Unknown"


func _on_window_mode_changed(index: int) -> void:
	SettingsManager.set_setting("display", "window_mode", index)
	SettingsManager.apply_display_settings()


func _on_vsync_changed(index: int) -> void:
	SettingsManager.set_setting("display", "vsync_mode", index)
	SettingsManager.apply_display_settings()


func _on_resolution_changed(index: int) -> void:
	var resolutions = [
		Vector2i(1280, 720),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3840, 2160)
	]
	
	var resolution = resolutions[index]
	SettingsManager.set_setting("display", "resolution_width", resolution.x)
	SettingsManager.set_setting("display", "resolution_height", resolution.y)
	SettingsManager.apply_display_settings()


func _on_rebind_pressed(action: String, binding_label: Label) -> void:
	binding_label.text = "Press key..."
	
	# Wait for next input
	var event = await _wait_for_input()
	
	if event:
		SettingsManager.rebind_input(action, event)
		binding_label.text = _get_binding_text(event)


func _on_reset_binding_pressed(action: String, binding_label: Label) -> void:
	SettingsManager.reset_input_action(action)
	var current_binding = SettingsManager.get_input_binding(action)
	binding_label.text = _get_binding_text(current_binding)


func _wait_for_input() -> InputEvent:
	while true:
		var event = await get_tree().root.gui_input

		if event is InputEventKey and event.pressed:
			return event
		elif event is InputEventMouseButton and event.pressed:
			return event
		elif event is InputEventJoypadButton and event.pressed:
			return event

	return null


func _on_back_pressed() -> void:
	if ResourceLoader.exists(Constants.SFX_UI_CLICK):
		AudioManager.play_sfx(preload(Constants.SFX_UI_CLICK))
	
	# Apply all settings before closing
	SettingsManager.apply_all_settings()
	
	SceneManager.pop_scene()