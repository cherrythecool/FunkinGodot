shader_type canvas_item;

uniform sampler2D overlay;
uniform float mix_factor : hint_range(0.0, 1.0, 0.01) = 0.5;

void fragment() {
	COLOR.rgb *= mix(vec3(1.0), texture(overlay, UV).rgb, mix_factor);
}
