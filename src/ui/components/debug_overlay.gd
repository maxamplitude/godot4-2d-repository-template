# src/ui/debug_overlay.gd
extends Control

@onready var fps_label := $"VBoxContainer/FPSLabel"
@onready var memory_label := $"VBoxContainer/MemoryLabel"
@onready var services_label := $"VBoxContainer/ServicesLabel"

func _ready():
	await get_tree().process_frame

	var events = GameServices.events
	if events:
		events.register_custom_event("debug_toggled")
		events.connect("debug_toggled", Callable(self, "_toggle_visibility"))

	visible = false

func _process(_delta):
	if not visible:
		return

	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	memory_label.text = "Memory: %.1f MB" % (OS.get_static_memory_usage() / 1024.0 / 1024.0)
	services_label.text = "Services: " + ", ".join(GameServices.get_loaded_services())

func _toggle_visibility(_data: Dictionary = {}) -> void:
	visible = not visible
