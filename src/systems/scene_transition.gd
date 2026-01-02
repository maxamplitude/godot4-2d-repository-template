extends Resource
class_name SceneTransition
## Base class for scene transitions
##
## Create custom transitions by extending this class and implementing
## transition_out() and transition_in() methods.

## Duration of the transition in seconds
@export var duration: float = 0.5

## Easing type for the transition
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT

## Transition timing function
@export var trans_type: Tween.TransitionType = Tween.TRANS_CUBIC


## Called when transitioning out (hiding current scene)
## Override this in custom transition classes
func transition_out(overlay: ColorRect) -> void:
	var tween = overlay.create_tween()
	tween.set_ease(ease_type)
	tween.set_trans(trans_type)
	_perform_transition_out(tween, overlay)
	await tween.finished


## Called when transitioning in (revealing new scene)
## Override this in custom transition classes
func transition_in(overlay: ColorRect) -> void:
	var tween = overlay.create_tween()
	tween.set_ease(ease_type)
	tween.set_trans(trans_type)
	_perform_transition_in(tween, overlay)
	await tween.finished


## Override this to define the transition out animation
func _perform_transition_out(tween: Tween, overlay: ColorRect) -> void:
	# Default: simple fade to black
	overlay.modulate.a = 0.0
	tween.tween_property(overlay, "modulate:a", 1.0, duration)


## Override this to define the transition in animation
func _perform_transition_in(tween: Tween, overlay: ColorRect) -> void:
	# Default: simple fade from black
	tween.tween_property(overlay, "modulate:a", 0.0, duration)


## Reset overlay to initial state after transition
func reset_overlay(overlay: ColorRect) -> void:
	overlay.modulate.a = 0.0
	overlay.position = Vector2.ZERO