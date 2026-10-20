shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec2 center = vec2(0.5, 0.5);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float smoothness : hint_range(0.001, 0.2) = 0.05;

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);

	vec2 aspect_correction = vec2(1920.0 / 1080.0, 1.0);

	vec2 scaled_uv = SCREEN_UV * aspect_correction;
	vec2 scaled_center = center * aspect_correction;
	float dist = length(scaled_uv - scaled_center);

	vec2 c = scaled_center;
	float max_dist = max(
		max(length(vec2(0.0, 0.0) * aspect_correction - c), length(vec2(1.0, 0.0) * aspect_correction - c)),
		max(length(vec2(0.0, 1.0) * aspect_correction - c), length(vec2(1.0, 1.0) * aspect_correction - c))
	);

	// Clean, direct mapping from outside the screen to past the center
	float current_radius = mix(max_dist + smoothness * 2.0, -smoothness * 2.0, progress);

	float edge_0 = current_radius - smoothness;
	float edge_1 = current_radius + smoothness;
	float mask = 1.0 - smoothstep(edge_0, edge_1, dist);

	vec3 final_color = mix(vec3(0.0), color.rgb, mask);

	COLOR = vec4(final_color, 1.0);
}