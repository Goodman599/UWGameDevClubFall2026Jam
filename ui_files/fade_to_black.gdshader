shader_type canvas_item;

// Grab whatever is currently on the screen behind this node
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// Progress ranges from 0.0 (fully transparent) to 1.0 (fully black)
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // Sample the screen using SCREEN_UV coordinates
    vec4 screen_color = texture(screen_texture, SCREEN_UV);
    
    // Mix the screen color with pure black based on the progress value
    vec3 final_color = mix(screen_color.rgb, vec3(0.0), progress);
    
    COLOR = vec4(final_color, 1.0);
}