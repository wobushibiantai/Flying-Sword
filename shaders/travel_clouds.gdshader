shader_type canvas_item;
render_mode unshaded;
uniform sampler2D cloud_texture : filter_nearest, repeat_enable;
uniform float cover : hint_range(0.0, 1.0) = 0.0;
uniform float drift = 0.0;

void fragment() {
    vec2 tile = UV + vec2(drift * 0.003, drift * 0.001);
    vec4 cloud = texture(cloud_texture, tile);
    COLOR = vec4(cloud.rgb, cover * (0.45 + cloud.a * 0.54));
}
