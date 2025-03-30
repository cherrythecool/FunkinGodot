shader_type canvas_item;

uniform float hue = 0.0;
uniform float saturation = 0.0;
uniform float contrast = 0.0;
uniform float brightness = 0.0;

vec3 applyHue(vec3 aColor, float aHue) {
    float angle = radians(aHue);
    vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(angle);
    return aColor * cosAngle + cross(k, aColor) * sin(angle) + k * dot(k, aColor) * (1.0 - cosAngle);
}

vec3 applyHSBCEffect(vec3 color) {
    color = clamp(color + ((brightness) / 255.0), 0.0, 1.0);
    color = applyHue(color, hue);
    color = clamp((color - 0.5) * (1.0 + ((contrast) / 255.0)) + 0.5, 0.0, 1.0);

    vec3 intensity = vec3(dot(color, vec3(0.30980392156, 0.60784313725, 0.08235294117)));
    color = clamp(mix(intensity, color, (1.0 + (saturation / 100.0))), 0.0, 1.0);

    return color;
}

void fragment() {
	vec3 hsv = applyHSBCEffect(COLOR.rgb);
	COLOR = vec4(hsv, COLOR.a);
}
