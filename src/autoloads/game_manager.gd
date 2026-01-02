extends Node
## Manages high-level game state, input handling, and game flow
##
## Handles pause/resume, quit confirmation, initial scene loading,
## and coordinates between different managers.

signal state_changed(old_state: Constants.GameState, new_state: Constants.GameState)

## Initial scene to load on game start
@export_file("*.tscn") var initial_scene: String = "res://src/ui/menus/main_menu.tscn"

## Enable pause menu on pause input
@export var pause_menu_enabled: bool = true

## Pause menu scene path
@export_file("*.tscn") var pause_menu_scene: String = "res://src/ui/menus/pause_menu.tscn"

## Enable quit confirmation dialog
@export var quit_confirmation_enabled: bool = true

## Allow quitting with Escape key in menus
@export var escape_quits_in_menu: bool = true

## Enable debug mode (F3 for debug overlay, etc.)
@export var debug_mode_enabled: bool = true

var _current_state: Constants.GameState = Constants.GameState.MENU
var _previous_state: Constants.GameState = Constants.GameState.MENU


func _ready() -> void:
	# Load initial scene (deferred to allow scene tree to finish initialization)
	if not initial_scene.is_empty():
		SceneManager.change_scene_immediate.call_deferred(initial_scene)
	
	# Connect to EventBus signals
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_ended.connect(_on_game_ended)
	EventBus.returned_to_menu.connect(_on_returned_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	# Pause handling
	var pause_pressed = event.is_action_pressed("ui_cancel")
	if InputMap.has_action("pause"):
		pause_pressed = pause_pressed or event.is_action_pressed("pause")
	
	if pause_pressed:
		_handle_pause_input()
		get_viewport().set_input_as_handled()
	
	# Debug mode toggle
	if debug_mode_enabled and InputMap.has_action("toggle_debug") and event.is_action_pressed("toggle_debug"):
		_toggle_debug_mode()
		get_viewport().set_input_as_handled()
	
	# Fullscreen toggle
	if InputMap.has_action("toggle_fullscreen") and event.is_action_pressed("toggle_fullscreen"):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()


## Change the current game state
func set_state(new_state: Constants.GameState) -> void:
	if _current_state == new_state:
		return
	
	_previous_state = _current_state
	_current_state = new_state
	state_changed.emit(_previous_state, _current_state)


## Get the current game state
func get_state() -> Constants.GameState:
	return _current_state


## Get the previous game state
func get_previous_state() -> Constants.GameState:
	return _previous_state


## Pause the game
func pause_game() -> void:
	if _current_state == Constants.GameState.PLAYING:
		get_tree().paused = true
		set_state(Constants.GameState.PAUSED)
		EventBus.game_paused.emit()
		
		if pause_menu_enabled and not pause_menu_scene.is_empty():
			SceneManager.push_scene(pause_menu_scene)


## Resume the game
func resume_game() -> void:
	if _current_state == Constants.GameState.PAUSED:
		get_tree().paused = false
		set_state(_previous_state)
		EventBus.game_resumed.emit()


## Quit the game with optional confirmation
func quit_game() -> void:
	if quit_confirmation_enabled and _current_state == Constants.GameState.PLAYING:
		# TODO: Show quit confirmation dialog
		# For now, just pause and let user decide
		pause_game()
	else:
		get_tree().quit()


## Return to main menu
func return_to_menu() -> void:
	get_tree().paused = false
	set_state(Constants.GameState.MENU)
	EventBus.returned_to_menu.emit()
	
	if not initial_scene.is_empty():
		SceneManager.change_scene(initial_scene)


func _handle_pause_input() -> void:
	match _current_state:
		Constants.GameState.PLAYING:
			pause_game()
		
		Constants.GameState.PAUSED:
			resume_game()
		
		Constants.GameState.MENU:
			if escape_quits_in_menu:
				quit_game()
		
		Constants.GameState.GAME_OVER:
			# Allow returning to menu from game over
			return_to_menu()


func _toggle_fullscreen() -> void:
	var current_mode = DisplayServer.window_get_mode()
	
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		SettingsManager.set_setting("display", "window_mode", 0)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		SettingsManager.set_setting("display", "window_mode", 1)


func _toggle_debug_mode() -> void:
	# Emit custom event for debug overlay to handle
	EventBus.emit_custom_event("debug_toggled", {})


func _on_game_started() -> void:
	set_state(Constants.GameState.PLAYING)


func _on_game_ended(victory: bool) -> void:
	set_state(Constants.GameState.GAME_OVER)


func _on_returned_to_menu() -> void:
	set_state(Constants.GameState.MENU)