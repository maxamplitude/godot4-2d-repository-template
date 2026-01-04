extends SceneTransition
class_name SlideTransition
## Slide transition from a specified direction

enum Direction { LEFT, RIGHT, UP, DOWN }

@export var direction: Direction = Direction.LEFT
@export var slide_color: Color = Color.BLACK


func _perform_transition_out(tween: Tween, overlay: ColorRect) -> void:
	overlay.color = slide_color
	overlay.modulate.a = 1.0
	
	var viewport_size = overlay.get_viewport_rect().size
	var start_pos = Vector2.ZERO
	
	match direction:
		Direction.LEFT:
			start_pos = Vector2(viewport_size.x, 0)
		Direction.RIGHT:
			start_pos = Vector2(-viewport_size.x, 0)
		Direction.UP:
			start_pos = Vector2(0, viewport_size.y)
		Direction.DOWN:
			start_pos = Vector2(0, -viewport_size.y)
	
	overlay.position = start_pos
	tween.tween_property(overlay, "position", Vector2.ZERO, duration)


func _perform_transition_in(tween: Tween, overlay: ColorRect) -> void:
	var viewport_size = overlay.get_viewport_rect().size
	var end_pos = Vector2.ZERO
	
	match direction:
		Direction.LEFT:
			end_pos = Vector2(-viewport_size.x, 0)
		Direction.RIGHT:
			end_pos = Vector2(viewport_size.x, 0)
		Direction.UP:
			end_pos = Vector2(0, -viewport_size.y)
		Direction.DOWN:
			end_pos = Vector2(0, viewport_size.y)
	
	tween.tween_property(overlay, "position", end_pos, duration)