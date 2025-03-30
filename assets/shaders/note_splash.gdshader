shader_type canvas_item;

uniform vec3 base_color : source_color = vec3(0.0);

void fragment() {
	COLOR.rgb += base_color;
}