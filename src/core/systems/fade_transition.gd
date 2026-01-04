extends SceneTransition
class_name FadeTransition
## Simple fade to/from black transition

@export var fade_color: Color = Color.BLACK


func _perform_transition_out(tween: Tween, overlay: ColorRect) -> void:
	overlay.color = fade_color
	overlay.modulate.a = 0.0
	tween.tween_property(overlay, "modulate:a", 1.0, duration)


func _perform_transition_in(tween: Tween, overlay: ColorRect) -> void:
	tween.tween_property(overlay, "modulate:a", 0.0, duration)