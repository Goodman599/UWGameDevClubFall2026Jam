shader_type canvas_item;

uniform float inner_radius : hint_range(0.0, 1.0) = 0.5;
uniform float blue_thickness : hint_range(0.0, 1.0) = 0.5;
uniform float black_thickness : hint_range(0.0, 0.1) = 0.05;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
// scale inner_radius I guess
// or if sprite scales, scale down white and black
// rad+white+black+black may not be supposed to exceed 1

void fragment() {
    // Get distance from center (0.5, 0.5)
    float dist = distance(UV, vec2(0.5));
	
	// sets transparency to 1 for the soundwave area
	float fill = step(dist, inner_radius) - step(dist, inner_radius - black_thickness - black_thickness - blue_thickness);
	// Create the 1st black outline
	float outline1 = step(dist, inner_radius) - step(dist, inner_radius - black_thickness);
	// Create the 2nd black outline
    float outline2 = step(dist, inner_radius - blue_thickness - black_thickness) - step(dist, inner_radius - blue_thickness - black_thickness - black_thickness);

    // Mix colors: Base is transparent, Fill is white, Outline is black
    vec4 color = vec4(0.67, 1.0, 1.0, fill); // Blue fill
    color.rgb = mix(color.rgb, vec3(0.0), outline1); // Overlay black outline
    color.rgb = mix(color.rgb, vec3(0.0), outline2); // Overlay black outline

    COLOR = color;
	// set opacity
	COLOR.a *= opacity;
}