# Generic camera controller
class_name CameraController extends Camera2D

@export var follow_smoothing := 5.0
@export var look_ahead_distance := 50.0
@export var shake_decay := 5.0

var shake_strength := 0.0
var target: Node2D

func shake(strength: float):
	shake_strength = strength

func _process(delta):
	if shake_strength > 0:
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
