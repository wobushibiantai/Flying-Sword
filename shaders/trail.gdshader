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
    float distance_from_axis = abs(UV.y - 0.5) * 8.0;
    float width = mix(0.12, 0.8, strength);
    float aa = max(fwidth(distance_from_axis), 0.25);
    float core = 1.0 - smoothstep(width - aa, width + aa, distance_from_axis);
    float glow = exp(-distance_from_axis * distance_from_axis * 0.55) * 0.09;
    vec3 tint = mix(vec3(0.83, 0.94, 0.55), vec3(0.45, 0.87, 0.77), trail_color.b * 0.45);
    COLOR = vec4(tint, (core * 0.7 + glow) * strength * strength);
}
