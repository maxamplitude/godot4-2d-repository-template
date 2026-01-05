extends Node2D
## Main scene root
##
## Handles initial setup, debug overlay, and global game initialization.
## This scene should remain loaded throughout the entire game session.

@onready var canvas_layer = $CanvasLayer
@onready var debug_overlay = $CanvasLayer/DebugOverlay
@onready var version_label = $CanvasLayer/VersionLabel
@onready var fps_label = $CanvasLayer/DebugOverlay/VBoxContainer/FPSLabel
@onready var memory_label = $CanvasLayer/DebugOverlay/VBoxContainer/MemoryLabel
@onready var services_label = $CanvasLayer/DebugOverlay/VBoxContainer/ServicesLabel


func _ready():
	await get_tree().process_frame
	# Set version in corner
	var version = ProjectSettings.get_setting("application/config/version", "1.0.0")
	version_label.text = "v" + version
	# Set initial game state
	GameServices.game.set_state(GameConstants.GameState.MENU)
	
	print("Main scene initialized")


func _process(_delta):
	if debug_overlay.visible:
		_update_debug_overlay()


func _update_debug_overlay():
	# FPS
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	
	# Memory usage
	var memory_static = OS.get_static_memory_usage() / 1024.0 / 1024.0  # MB
	memory_label.text = "Memory: %.1f MB" % memory_static
	
	# Loaded services
	var loaded = GameServices.get_loaded_services()
	services_label.text = "Services: " + ", ".join(loaded)