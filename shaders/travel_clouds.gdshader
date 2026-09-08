shader_type canvas_item;
render_mode unshaded;
uniform float cover : hint_range(0.0, 1.0) = 0.0;
uniform float drift = 0.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
    vec2 p=UV*vec2(6.0,4.0)+vec2(drift*0.04,drift*0.012);
    float n=noise(p)*0.58+noise(p*2.1)*0.28+noise(p*4.2)*0.14;
    float puff=smoothstep(0.25,0.72,n);
    float alpha=clamp(cover*(0.42+puff*0.8),0.0,1.0);
    COLOR=vec4(mix(vec3(0.62,0.77,0.83),vec3(0.95,0.98,0.97),puff),alpha);
}
