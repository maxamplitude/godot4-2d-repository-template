extends SceneTransition
class_name CircularWipeTransition
## Circular wipe transition (iris in/out effect)

@export var wipe_color: Color = Color.BLACK
@export var center_position: Vector2 = Vector2(0.5, 0.5)  # Normalized (0-1)
@export var invert: bool = false  # If true, wipe out from center; if false, wipe in to center

var _shader: Shader


func _init() -> void:
	_shader = Shader.new()
	_shader.code = """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform bool invert = false;

void fragment() {
	vec2 uv = UV;
	float dist = distance(uv, center);
	float max_dist = length(vec2(0.5, 0.5));
	
	float normalized_dist = dist / max_dist;
	float alpha = invert ? 
		step(normalized_dist, progress) : 
		step(progress, normalized_dist);
	
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""


func _perform_transition_out(tween: Tween, overlay: ColorRect) -> void:
	overlay.color = wipe_color
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = _shader
	shader_material.set_shader_parameter("center", center_position)
	shader_material.set_shader_parameter("invert", invert)
	shader_material.set_shader_parameter("progress", 0.0)
	
	overlay.material = shader_material
	tween.tween_method(
		func(value): shader_material.set_shader_parameter("progress", value),
		0.0, 1.0, duration
	)


func _perform_transition_in(tween: Tween, overlay: ColorRect) -> void:
	if overlay.material and overlay.material is ShaderMaterial:
		var shader_material = overlay.material as ShaderMaterial
		tween.tween_method(
			func(value): shader_material.set_shader_parameter("progress", value),
			1.0, 0.0, duration
		)


func reset_overlay(overlay: ColorRect) -> void:
	super.reset_overlay(overlay)
	overlay.material = null