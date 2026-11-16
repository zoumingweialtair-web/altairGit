shader_type canvas_item;
render_mode unshaded;
uniform vec4 sky_top : source_color = vec4(0.60,0.76,0.84,1.0);
uniform vec4 sky_bottom : source_color = vec4(0.83,0.88,0.82,1.0);
uniform vec4 glow_color : source_color = vec4(0.96,0.83,0.65,1.0);
uniform float glow = 0.15;
uniform float clock = 0.0;
void fragment() {
    float height = smoothstep(0.0,0.60,UV.y);
    vec3 sky = mix(sky_top.rgb,sky_bottom.rgb,height);
    float horizon = exp(-pow((UV.y-0.39)/0.15,2.0));
    sky = mix(sky,glow_color.rgb,horizon*glow);
    COLOR = vec4(sky,1.0);
}
