# src/ui/debug_overlay.gd
extends CanvasLayer

@onready var fps_label := %FPSLabel
@onready var info_label := %InfoLabel

func _ready():
	EventBus.register_custom_event("debug_toggled")
	EventBus.connect("debug_toggled", _toggle_visibility)
	visible = false

func _process(_delta):
	if visible:
	    fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	    info_label.text = "Objects: %d" % get_tree().get_node_count()
