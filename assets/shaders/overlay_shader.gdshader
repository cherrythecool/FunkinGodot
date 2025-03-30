shader_type canvas_item;

uniform sampler2D funnyShit;

vec4 blendOverlay(vec4 base, vec4 blend) {
	vec4 mixed = mix(1.0 - 2.0 * (1.0 - base) * (1.0 - blend), 2.0 * base * blend, step(base, vec4(0.5)));
	return mixed;
}

void fragment() {
    vec4 color = texture(TEXTURE, UV);
	vec2 reallyFunnyUv = vec2(vec2(0.0) - FRAGCOORD.xy / TEXTURE_PIXEL_SIZE.xy);
	vec4 gf = texture(funnyShit, UV.xy + vec2(0.1, 0.2));
    COLOR = blendOverlay(color, gf);
}