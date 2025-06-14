shader_type canvas_item;

uniform float fade : hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	COLOR -= fade * float(COLOR.a > 0.0);
}
