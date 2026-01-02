extends Node
## Manages game settings and user preferences
##
## Uses ConfigFile for persistent settings storage including audio volumes,
## display options, input bindings, and custom game settings.

signal setting_changed(section: String, key: String, value: Variant)

## Path to settings file
@export var settings_file_path: String = "user://settings.cfg"

## Default window mode (0=Windowed, 1=Fullscreen, 2=Borderless)
@export var default_window_mode: int = 0

## Default resolution width
@export var default_resolution_width: int = 1920

## Default resolution height
@export var default_resolution_height: int = 1080

## Default VSync mode (0=Disabled, 1=Enabled, 2=Adaptive)
@export var default_vsync_mode: int = 1

## Default master volume (0.0 to 1.0)
@export var default_master_volume: float = 1.0

## Default music volume (0.0 to 1.0)
@export var default_music_volume: float = 0.8

## Default SFX volume (0.0 to 1.0)
@export var default_sfx_volume: float = 1.0

## Default UI volume (0.0 to 1.0)
@export var default_ui_volume: float = 1.0

## Default ambience volume (0.0 to 1.0)
@export var default_ambience_volume: float = 0.8

## Default voice volume (0.0 to 1.0)
@export var default_voice_volume: float = 0.8

var _config: ConfigFile
var _settings_cache: Dictionary = {}
var _has_warned_display_skip: bool = false


func _ready() -> void:
	_config = ConfigFile.new()
	load_settings()
	apply_all_settings()


## Load settings from disk
func load_settings() -> void:
	var err = _config.load(settings_file_path)
	
	if err != OK:
		push_warning("SettingsManager: Failed to load settings file, using defaults")
		_set_default_settings()
		save_settings()
	
	_cache_all_settings()


## Save current settings to disk
func save_settings() -> void:
	# CI environments often have restricted user directories which causes hangs on exit
	if DisplayServer.get_name() == "headless" or OS.has_feature("headless"):
		return

	if not _config:
		return

	var err = _config.save(settings_file_path)
	if err != OK:
		push_error("SettingsManager: Failed to save settings file")


## Get a setting value
func get_setting(section: String, key: String, default_value: Variant = null) -> Variant:
	var cache_key = section + ":" + key
	if cache_key in _settings_cache:
		return _settings_cache[cache_key]

	if not _config:
		_config = ConfigFile.new()

	var value = default_value
	if _config:
		value = _config.get_value(section, key, default_value)

	_settings_cache[cache_key] = value
	return value


## Set a setting value and optionally save immediately
func set_setting(section: String, key: String, value: Variant, save_immediately: bool = true) -> void:
	_config.set_value(section, key, value)
	
	var cache_key = section + ":" + key
	_settings_cache[cache_key] = value
	
	if save_immediately:
		save_settings()
	
	setting_changed.emit(section, key, value)
	EventBus.settings_changed.emit(section, key, value)


## Check if a setting exists
func has_setting(section: String, key: String) -> bool:
	return _config.has_section_key(section, key)


## Remove a setting
func remove_setting(section: String, key: String) -> void:
	_config.erase_section_key(section, key)
	var cache_key = section + ":" + key
	_settings_cache.erase(cache_key)


## Reset all settings to defaults
func reset_to_defaults() -> void:
	_config.clear()
	_set_default_settings()
	save_settings()
	apply_all_settings()


## Apply all settings to the game
func apply_all_settings() -> void:
	apply_display_settings()
	apply_audio_settings()
	apply_input_settings()


## Apply display settings
func apply_display_settings() -> void:
	# Skip display changes when running in environments that don't support window control
	# (embedded run inside the editor or headless CI). Trying to resize/move a window
	# there produces noisy warnings like "Embedded window can't be resized."
	var is_headless := OS.has_feature("headless")
	var is_embedded := Engine.is_embedded_in_editor()
	if is_headless or is_embedded:
		if not _has_warned_display_skip:
			var reason := "headless" if is_headless else "embedded window"
			push_warning("SettingsManager: Skipping display settings while running in %s mode." % reason)
			_has_warned_display_skip = true
		return

	var window_mode = get_setting("display", "window_mode", default_window_mode)
	var resolution_width = get_setting("display", "resolution_width", default_resolution_width)
	var resolution_height = get_setting("display", "resolution_height", default_resolution_height)
	var vsync_mode = get_setting("display", "vsync_mode", default_vsync_mode)
	
	# Window mode
	match window_mode:
		0:  # Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:  # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:  # Borderless
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	# Resolution (only in windowed mode)
	if window_mode == 0:
		DisplayServer.window_set_size(Vector2i(resolution_width, resolution_height))
		var screen_size = DisplayServer.screen_get_size()
		var window_size = DisplayServer.window_get_size()
		var centered_pos = (screen_size - window_size) / 2
		DisplayServer.window_set_position(centered_pos)
	
	# VSync
	match vsync_mode:
		0:  # Disabled
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		1:  # Enabled
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		2:  # Adaptive
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)


## Apply audio settings
func apply_audio_settings() -> void:
	if not AudioManager:
		return
	
	var master_volume = get_setting("audio", "master_volume", default_master_volume)
	var music_volume = get_setting("audio", "music_volume", default_music_volume)
	var sfx_volume = get_setting("audio", "sfx_volume", default_sfx_volume)
	var ui_volume = get_setting("audio", "ui_volume", default_ui_volume)
	
	AudioManager.set_bus_volume("Master", master_volume)
	AudioManager.set_bus_volume("Music", music_volume)
	AudioManager.set_bus_volume("SFX", sfx_volume)
	AudioManager.set_bus_volume("UI", ui_volume)


## Apply input settings (keybindings)
func apply_input_settings() -> void:
	# Load custom keybindings if they exist
	if not _config.has_section("input"):
		return
	
	for action in _config.get_section_keys("input"):
		var key_code = get_setting("input", action, 0)
		if key_code > 0:
			_rebind_action(action, key_code)


## Rebind an input action to a new key
func rebind_input(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		push_warning("SettingsManager: Action '%s' does not exist" % action)
		return
	
	# Remove existing bindings
	InputMap.action_erase_events(action)
	
	# Add new binding
	InputMap.action_add_event(action, event)
	
	# Save to config
	if event is InputEventKey:
		set_setting("input", action, event.keycode)
	elif event is InputEventMouseButton:
		set_setting("input", action, event.button_index)
	elif event is InputEventJoypadButton:
		set_setting("input", action, event.button_index)


## Get the current keybinding for an action
func get_input_binding(action: String) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	
	var events = InputMap.action_get_events(action)
	if events.is_empty():
		return null
	
	return events[0]


## Reset a specific input action to default
func reset_input_action(action: String) -> void:
	if has_setting("input", action):
		remove_setting("input", action)
		# Reload default from InputMap would require storing defaults separately
		# For now, just clear the custom binding


func _set_default_settings() -> void:
	# Display defaults
	set_setting("display", "window_mode", default_window_mode, false)
	set_setting("display", "resolution_width", default_resolution_width, false)
	set_setting("display", "resolution_height", default_resolution_height, false)
	set_setting("display", "vsync_mode", default_vsync_mode, false)
	
	# Audio defaults
	set_setting("audio", "master_volume", default_master_volume, false)
	set_setting("audio", "music_volume", default_music_volume, false)
	set_setting("audio", "sfx_volume", default_sfx_volume, false)
	set_setting("audio", "ui_volume", default_ui_volume, false)
	set_setting("audio", "ambience_volume", default_ambience_volume, false)
	set_setting("audio", "voice_volume", default_voice_volume, false)


func _cache_all_settings() -> void:
	_settings_cache.clear()
	
	for section in _config.get_sections():
		for key in _config.get_section_keys(section):
			var cache_key = section + ":" + key
			_settings_cache[cache_key] = _config.get_value(section, key)


func _rebind_action(action: String, key_code: int) -> void:
	if not InputMap.has_action(action):
		return
	
	InputMap.action_erase_events(action)
	
	var event = InputEventKey.new()
	event.keycode = key_code
	InputMap.action_add_event(action, event)