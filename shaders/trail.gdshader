shader_type canvas_item;
render_mode unshaded;
varying vec4 trail_color;

void vertex() {
    vec2 start = INSTANCE_CUSTOM.xy;
    vec2 end = INSTANCE_CUSTOM.zw;
    vec2 direction = end - start;
    vec2 normal = vec2(-direction.y, direction.x) / max(length(direction), 0.001);
    VERTEX = mix(start, end, UV.x) + normal * (UV.y - 0.5) * 8.0;
    trail_color = COLOR;
}

void fragment() {
    float strength = mix(trail_color.r, trail_color.g, UV.x);
    // Aseprite-authored stepped light bands; no procedural blurred halo.
    vec4 ink = texture(TEXTURE, UV);
    vec3 tint = mix(vec3(1.0), vec3(0.68, 1.0, 0.91), trail_color.b * 0.45);
    COLOR = vec4(ink.rgb * tint, ink.a * strength * strength);
}
