shader_type canvas_item;
render_mode unshaded;
varying float roll_phase;
varying float tint;

void vertex() {
    roll_phase = INSTANCE_CUSTOM.x;
    tint = INSTANCE_CUSTOM.y;
    // Projection of a blade rotating about its longitudinal X axis.
    // A finite edge thickness keeps the blade visible at 90 / 270 degrees.
    VERTEX.x += 4.0;
    float face = cos(roll_phase);
    VERTEX.y *= max(abs(face), 0.10) * (face < 0.0 ? -1.0 : 1.0);
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float face = cos(roll_phase);
    float highlight = pow(max(0.0, sin(roll_phase + UV.y * 0.9)), 12.0);
    vec3 shade = mix(vec3(0.52, 0.72, 0.66), vec3(1.0), face * 0.5 + 0.5);
    tex.rgb *= shade * mix(vec3(1.0), vec3(0.77, 1.0, 0.94), tint * 0.45);
    tex.rgb += vec3(0.35, 0.4, 0.24) * highlight * step(0.45, UV.x);
    COLOR = tex;
}
