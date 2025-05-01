shader_type canvas_item;

uniform vec3 target_color : source_color = vec3(0.0, 1.0, 0.0);
uniform float tolerance : hint_range(0.0, 100.0, 0.1) = 75.0;

void fragment() {
	COLOR.a *= 1.0 - float(length(COLOR.rgb - target_color)*100.0 < 100.0 - tolerance);
}
