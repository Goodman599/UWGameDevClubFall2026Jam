shader_type canvas_item;

// Captures everything rendered behind this node
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Customization parameters
uniform float intensity : hint_range(0.0, 1.0) = 1.0; // Controls overall effect strength
uniform float edge_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float edge_spread : hint_range(0.0, 1.0) = 0.5;
uniform vec4 blue_tint : source_color = vec4(0.0, 0.35, 1.0, 1.0);

void fragment() {
	// Sample the background screen pixels
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);

	// 1. Convert everything to greyscale using standard luminance weights
	float grey = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 greyscale_color = vec3(grey);

	// 2. Calculate distance from the center of the screen for edge detection
	vec2 center_distance = SCREEN_UV - 0.5;
	float dist = length(center_distance);

	// Create a smooth mask for the edges (vignette)
	float edge_mask = smoothstep(0.2, 0.5 + edge_intensity, dist);

	// 3. Blend the greyscale world with the blue edge tint
	vec3 final_color = mix(greyscale_color, blue_tint.rgb, edge_mask * edge_spread);

	// 4. Blend the original color with the shader effect based on the intensity parameter
	vec3 blended_output = mix(color.rgb, final_color, intensity);

	COLOR = vec4(blended_output, color.a);
}