shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment() {
	COLOR.rgb = vec3(dot(texture(SCREEN_TEXTURE, SCREEN_UV).rgb, vec3(1.0 / 3.0)));
}
