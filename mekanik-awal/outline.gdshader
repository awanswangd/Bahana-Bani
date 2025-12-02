shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); 
uniform float line_thickness : hint_range(0.0, 10.0) = 0.0; 

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE;
    
    float outline = 0.0;
    
    outline += texture(TEXTURE, UV + vec2(-size.x, 0.0) * line_thickness).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0.0) * line_thickness).a;
    outline += texture(TEXTURE, UV + vec2(0.0, -size.y) * line_thickness).a;
    outline += texture(TEXTURE, UV + vec2(0.0, size.y) * line_thickness).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, -size.y) * line_thickness).a;
    outline += texture(TEXTURE, UV + vec2(size.x, size.y) * line_thickness).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, size.y) * line_thickness).a;
    outline += texture(TEXTURE, UV + vec2(size.x, -size.y) * line_thickness).a;
    
    outline = min(outline, 1.0);
    
    vec4 color = texture(TEXTURE, UV);
    
    COLOR = mix(color, line_color, outline - color.a);
}