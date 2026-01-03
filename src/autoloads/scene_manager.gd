extends Node
## Manages scene transitions, loading, and scene stacking
##
## Handles scene changes with customizable transitions, loading screens for
## heavy scenes, and maintains a scene stack for pause/overlay management.

signal scene_loaded(scene_path: String)
signal scene_unloaded(scene_path: String)
signal transition_started
signal transition_finished

## Default transition effect (can be any SceneTransition resource)
@export var default_transition: SceneTransition = null

## Use instant transition when no transition is specified
@export var instant_when_null: bool = true

## Path to loading screen scene (optional)
@export var loading_screen_scene: String = ""

## Minimum time to show loading screen (prevents flashing)
@export var min_loading_time: float = 0.5

## Preload these scenes at startup
@export var scenes_to_preload: Array[String] = []

var _current_scene: Node = null
var _scene_stack: Array[Node] = []
var _preloaded_scenes: Dictionary = {}
var _transition_overlay: ColorRect
var _is_transitioning: bool = false
var _skip_current_scene_cleanup: bool = false  # Flag to prevent freeing during push


func _ready() -> void:
	await get_tree().process_frame  # Let all autoloads initialize
	_setup_transition_overlay()
	_preload_scenes()
	
	# Capture the initial scene
	var root = get_tree().root
	_current_scene = root.get_child(root.get_child_count() - 1)


func _setup_transition_overlay() -> void:
	_transition_overlay = ColorRect.new()
	_transition_overlay.color = Color.BLACK
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_overlay.modulate.a = 0.0
	
	# Make it cover the entire viewport
	_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_overlay.z_index = 1000
	
	get_tree().root.call_deferred("add_child", _transition_overlay)


func _preload_scenes() -> void:
	for scene_path in scenes_to_preload:
		if ResourceLoader.exists(scene_path):
			_preloaded_scenes[scene_path] = load(scene_path)
		else:
			push_warning("SceneManager: Cannot preload '%s' - file not found" % scene_path)


## Change to a new scene with optional transition
func change_scene(scene_path: String, transition: SceneTransition = null, use_loading_screen: bool = false) -> void:
	if _is_transitioning:
		push_warning("SceneManager: Already transitioning, ignoring change_scene call")
		return
	
	# Use default transition if none specified
	if transition == null:
		transition = default_transition
	
	_is_transitioning = true
	transition_started.emit()
	
	if transition == null and instant_when_null:
		_perform_scene_change(scene_path)
		_is_transitioning = false
		transition_finished.emit()
	else:
		await _play_transition(transition, scene_path, use_loading_screen)
		_is_transitioning = false
		transition_finished.emit()


## Change scene instantly without transition
func change_scene_immediate(scene_path: String) -> void:
	_perform_scene_change(scene_path)


## Reload the current scene
func reload_scene(transition: SceneTransition = null) -> void:
	if _current_scene:
		change_scene(_current_scene.scene_file_path, transition)


## Push current scene onto stack and load new scene (for overlays/menus)
func push_scene(scene_path: String, transition: SceneTransition = null) -> void:
	if _current_scene:
		_scene_stack.append(_current_scene)
		_current_scene.process_mode = Node.PROCESS_MODE_DISABLED
	
	if transition == null:
		transition = default_transition
	
	if _is_transitioning:
		push_warning("SceneManager: Already transitioning, ignoring push_scene call")
		return
	
	_is_transitioning = true
	_skip_current_scene_cleanup = true  # Don't free the scene we just pushed
	transition_started.emit()
	
	await _play_transition(transition, scene_path, false)
	
	_skip_current_scene_cleanup = false  # Reset flag
	_is_transitioning = false
	transition_finished.emit()


## Pop the top scene from stack and return to previous scene
func pop_scene(transition: SceneTransition = null) -> void:
	if _scene_stack.is_empty():
		push_warning("SceneManager: No scenes in stack to pop")
		return
	
	if transition == null:
		transition = default_transition
	
	if _is_transitioning:
		push_warning("SceneManager: Already transitioning, ignoring pop_scene call")
		return
	
	_is_transitioning = true
	transition_started.emit()
	
	if transition:
		await transition.transition_out(_transition_overlay)
	
	# Remove current scene
	if _current_scene:
		var old_scene_path = _current_scene.scene_file_path
		_current_scene.queue_free()
		scene_unloaded.emit(old_scene_path)
	
	# Restore previous scene
	_current_scene = _scene_stack.pop_back()
	
	# Validate the restored scene
	if not is_instance_valid(_current_scene):
		push_error("SceneManager: Scene from stack is invalid/freed")
		_current_scene = null
		_is_transitioning = false
		return
	
	_current_scene.process_mode = Node.PROCESS_MODE_INHERIT
	
	if transition:
		await transition.transition_in(_transition_overlay)
		transition.reset_overlay(_transition_overlay)
	
	_is_transitioning = false
	transition_finished.emit()


## Get reference to the current scene
func get_current_scene() -> Node:
	return _current_scene


## Check if a scene is preloaded
func is_scene_preloaded(scene_path: String) -> bool:
	return scene_path in _preloaded_scenes


func _perform_scene_change(scene_path: String) -> void:
	if _current_scene and not _skip_current_scene_cleanup:
		_current_scene.queue_free()
		scene_unloaded.emit(_current_scene.scene_file_path)

	var loaded_resource = _preloaded_scenes.get(scene_path, null)
	if not loaded_resource:
		loaded_resource = load(scene_path)
	if not loaded_resource:
		push_error("SceneManager: Failed to load scene '%s'" % scene_path)
		_is_transitioning = false
		return

	var new_scene = loaded_resource.instantiate()
	get_tree().root.call_deferred("add_child", new_scene)
	call_deferred("_set_current_scene_deferred", new_scene, scene_path)
	_current_scene = new_scene


func _set_current_scene_deferred(new_scene: Node, scene_path: String) -> void:
	get_tree().current_scene = new_scene
	scene_loaded.emit(scene_path)


func _load_scene_with_loading_screen(scene_path: String) -> void:
	# Show loading screen
	var loading_screen = load(loading_screen_scene).instantiate()
	get_tree().root.call_deferred("add_child", loading_screen)
	await get_tree().process_frame
	
	var start_time = Time.get_ticks_msec()
	
	# Load scene in background
	_perform_scene_change(scene_path)
	await get_tree().process_frame
	
	# Ensure minimum loading time
	var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
	if elapsed < min_loading_time:
		await get_tree().create_timer(min_loading_time - elapsed).timeout
	
	# Remove loading screen
	loading_screen.queue_free()


func _play_transition(transition: SceneTransition, scene_path: String, use_loading_screen: bool) -> void:
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if transition:
		await transition.transition_out(_transition_overlay)
	
	if use_loading_screen and not loading_screen_scene.is_empty():
		await _load_scene_with_loading_screen(scene_path)
	else:
		_perform_scene_change(scene_path)
	
	if transition:
		await transition.transition_in(_transition_overlay)
		transition.reset_overlay(_transition_overlay)
	
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
