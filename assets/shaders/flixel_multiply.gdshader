shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment() {
	vec4 SCREEN_COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR.rgb *= SCREEN_COLOR.rgb;
}
