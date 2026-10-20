shader_type canvas_item;

// Toggle to turn the color replacement on or off
uniform bool enabled = true;

uniform vec4 target_color : source_color = vec4(0.0, 0.584, 1.0, 1.0);
uniform vec4 replacement_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tolerance : hint_range(0.0, 0.5) = 0.1;

void fragment() {
    vec4 current_color = texture(TEXTURE, UV);
    
    // Only perform the color swap if 'enabled' is true and the pixel isn't transparent
    if (enabled && current_color.a > 0.0) {
        float diff = distance(current_color.rgb, target_color.rgb);
        
        if (diff < tolerance) {
            current_color.rgb = replacement_color.rgb;
        }
    }
    
    COLOR = current_color;
}