shader_type canvas_item;
render_mode unshaded;
uniform sampler2D water_tile : repeat_enable, filter_linear;
uniform float tile_amount = 0.0;
uniform float clock = 0.0;
uniform float horizon = 0.526;
uniform vec4 water_color : source_color = vec4(0.40,0.65,0.70,1.0);
uniform vec4 reflection_color : source_color = vec4(0.84,0.89,0.80,1.0);
uniform float reflection_strength = 0.32;
uniform float wind_strength = 0.3;
uniform float rain_strength = 0.0;
uniform float blue_tide = 0.0;
uniform float gold_tide = 0.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
    float depth = clamp((UV.y-horizon)/(1.0-horizon),0.0,1.0);
    vec2 moving_uv = vec2(UV.x*2.35+clock*0.007,depth*1.7-clock*0.008);
    moving_uv.x += sin(depth*19.0+clock*0.6)*0.004*(0.4+wind_strength);
    float texture_light = dot(texture(water_tile,moving_uv).rgb,vec3(0.21,0.72,0.07));
    // Irregular, broken glints follow individual ripples instead of long sine bands.
    vec2 cell_uv = vec2((UV.x+sin(depth*7.0+clock*0.11)*0.006)*69.0,(depth+sin(UV.x*3.0)*0.025)*94.0);
    vec2 cell = floor(cell_uv);
    vec2 local = fract(cell_uv);
    float seed = hash(cell);
    float line_y = 0.20+seed*0.57;
    float short_line = 1.0-smoothstep(0.035,0.11,abs(local.y-line_y));
    float length_mask = smoothstep(0.02,0.15,local.x)*(1.0-smoothstep(0.28+seed*0.55,0.43+seed*0.55,local.x));
    float shimmer = 0.35+0.65*pow(0.5+0.5*sin(clock*(0.5+wind_strength*0.2)+seed*16.0),2.0);
    float streak = short_line*length_mask*step(0.57,seed)*shimmer;
    vec3 color = water_color.rgb*(0.88+depth*0.12);
    color += (texture_light-0.42)*tile_amount*0.68;
    float path_center = 0.62+sin(depth*8.0+clock*0.11)*0.012;
    float path = exp(-pow((UV.x-path_center)/(0.024+depth*0.047),2.0));
    float reflection = path*reflection_strength*streak*0.68;
    color = mix(color,reflection_color.rgb,clamp(reflection+streak*0.09,0.0,0.6));
    float patch = 0.25+0.75*hash(floor(vec2(UV.x*11.0+clock*0.025,depth*13.0)));
    float glow = (streak*0.8+smoothstep(0.46,0.56,texture_light)*0.55)*patch*blue_tide;
    color = mix(color,vec3(0.31,0.80,0.79),glow);
    color = mix(color,vec3(0.91,0.72,0.43),gold_tide*path*streak*0.55);
    float droplets = step(0.986,hash(floor(vec2(UV.x*230.0,UV.y*160.0-clock*4.0))));
    color += droplets*rain_strength*0.10;
    COLOR = vec4(color,smoothstep(horizon-0.003,horizon+0.003,UV.y));
}
