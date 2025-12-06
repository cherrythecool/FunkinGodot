shader_type canvas_item;

uniform vec2 block_size = vec2(1.0);

varying vec4 MODULATE;

void vertex() {
	MODULATE = COLOR;
}

void fragment() {
	vec2 blocks = (1.0 / TEXTURE_PIXEL_SIZE) / block_size;
	COLOR = texture(TEXTURE, floor(UV * blocks) / blocks) * MODULATE;
}
