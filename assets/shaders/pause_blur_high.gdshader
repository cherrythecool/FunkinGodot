shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float lod: hint_range(-2.0, 10.0) = 0.0;
varying vec4 MODULATE;

void vertex() {
	MODULATE = COLOR;
}

void fragment() {
	COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, lod) * MODULATE;
}
