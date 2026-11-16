shader_type canvas_item;
render_mode unshaded;
uniform vec4 light_tint : source_color = vec4(1.0);
uniform vec4 wash_color : source_color = vec4(0.75,0.82,0.84,1.0);
uniform float wash_strength = 0.0;
uniform float snow_cover = 0.0;
uniform float leaf_layer = 0.0;
uniform float foreground_layer = 0.0;
uniform float town_layer = 0.0;
uniform float window_light = 0.0;
uniform float sway_pixels = 0.0;
uniform float wind_strength = 0.3;
uniform float clock = 0.0;
float box_mask(vec2 p,vec4 bounds) {
    return step(bounds.x,p.x)*step(bounds.y,p.y)*(1.0-step(bounds.z,p.x))*(1.0-step(bounds.w,p.y));
}
float patch_noise(vec2 p) { return fract(sin(dot(floor(p),vec2(127.1,311.7)))*43758.5453); }
float triangle_mask(vec2 p,vec2 a,vec2 b,vec2 c) {
    float d1=(p.x-b.x)*(a.y-b.y)-(a.x-b.x)*(p.y-b.y);
    float d2=(p.x-c.x)*(b.y-c.y)-(b.x-c.x)*(p.y-c.y);
    float d3=(p.x-a.x)*(c.y-a.y)-(c.x-a.x)*(p.y-a.y);
    bool negative=d1<0.0 || d2<0.0 || d3<0.0;
    bool positive=d1>0.0 || d2>0.0 || d3>0.0;
    return negative && positive ? 0.0 : 1.0;
}
float roof_quad(vec2 p,vec2 a,vec2 b,vec2 c,vec2 d) {
    return max(triangle_mask(p,a,b,c),triangle_mask(p,a,c,d));
}
void fragment() {
    vec2 coord = UV;
    vec4 base = texture(TEXTURE,coord);
    float leaf = smoothstep(0.01,0.13,base.g-max(base.r,base.b)*0.91);
    float crown = 1.0-smoothstep(0.20,0.78,UV.y);
    coord.x += sin(clock*(0.65+wind_strength*0.2)+UV.y*24.0)*sway_pixels/1440.0*leaf_layer*crown*leaf;
    base = texture(TEXTURE,coord);
    float brightness = dot(base.rgb,vec3(0.21,0.72,0.07));
    float darkness = clamp(1.0-dot(light_tint.rgb,vec3(0.21,0.72,0.07)),0.0,1.0);
    vec3 surface = mix(base.rgb,vec3(brightness),darkness*0.42);
    vec3 color = surface*light_tint.rgb;
    // Luminance-preserving palette mapping gives night and fantasy light its hue,
    // rather than leaving daylight-yellow leaves underneath a dark multiplier.
    vec3 shadow_ink = mix(wash_color.rgb,light_tint.rgb,0.28)*0.40;
    vec3 lit_ink = light_tint.rgb*1.06;
    vec3 light_palette = mix(shadow_ink,lit_ink,pow(clamp(brightness,0.0,1.0),0.88));
    color = mix(color,light_palette,clamp(darkness*1.78,0.0,0.89));
    float desk = smoothstep(0.875,0.915,UV.y);
    float desk_objects = box_mask(UV,vec4(0.245,0.842,0.525,1.0));
    float indoor = max(desk,desk_objects)*foreground_layer;
    vec3 indoor_tint = mix(light_tint.rgb,vec3(1.0,0.93,0.83),0.25);
    color = mix(color,base.rgb*indoor_tint,indoor);
    color = mix(color,wash_color.rgb,wash_strength);
    // Snow rests on bright roof/leaf planes; it never outlines the whole shore.
    float clay = smoothstep(0.055,0.14,base.r-base.b)*smoothstep(0.015,0.075,base.r-base.g);
    // These three registered polygons follow the sloping tile planes, never walls.
    float near_roofs=roof_quad(UV,vec2(0.826,0.216),vec2(0.968,0.071),vec2(0.968,0.137),vec2(0.849,0.231));
    near_roofs+=roof_quad(UV,vec2(0.724,0.511),vec2(0.855,0.421),vec2(0.855,0.474),vec2(0.732,0.535));
    near_roofs+=roof_quad(UV,vec2(0.658,0.640),vec2(0.729,0.585),vec2(0.747,0.588),vec2(0.747,0.638));
    float far_roofs=box_mask(UV,vec4(0.250,0.437,0.331,0.465));
    far_roofs+=box_mask(UV,vec4(0.346,0.475,0.380,0.492));
    far_roofs+=box_mask(UV,vec4(0.402,0.489,0.430,0.506));
    far_roofs+=box_mask(UV,vec4(0.581,0.501,0.621,0.518));
    far_roofs+=box_mask(UV,vec4(0.700,0.444,0.775,0.471));
    float roof_area=foreground_layer*clamp(near_roofs,0.0,1.0)+town_layer*clamp(far_roofs,0.0,1.0)*0.6;
    float patches = smoothstep(0.20,0.73,patch_noise(UV*vec2(830.0,480.0))*0.62+brightness*0.48);
    float snow_roof = roof_area*clay*patches*smoothstep(0.28,0.55,brightness)*0.94;
    float balcony_leaf = 0.0;
    float snow_leaf = (leaf_layer*0.61+balcony_leaf*0.44)*leaf*patches*smoothstep(0.27,0.62,brightness);
    float snow_mask = clamp(snow_roof+snow_leaf,0.0,1.0)*snow_cover*(1.0-indoor);
    color = mix(color,vec3(0.88,0.93,0.91)*mix(vec3(1.0),light_tint.rgb,0.25),snow_mask);
    float nearby_windows = box_mask(UV,vec4(0.897,0.257,0.949,0.396));
    nearby_windows += box_mask(UV,vec4(0.889,0.501,0.949,0.653));
    nearby_windows += box_mask(UV,vec4(0.771,0.552,0.810,0.650));
    float warm_glass = smoothstep(0.045,0.16,base.r-base.b)*smoothstep(0.24,0.57,brightness);
    float near_light = foreground_layer*nearby_windows*warm_glass*window_light*0.85;
    color = mix(color,base.rgb*vec3(1.08,0.95,0.70)+vec3(0.035,0.018,0.0),near_light);
    float town_windows = box_mask(UV,vec4(0.254,0.455,0.350,0.520));
    town_windows += box_mask(UV,vec4(0.358,0.483,0.426,0.530));
    town_windows += box_mask(UV,vec4(0.583,0.508,0.612,0.542));
    town_windows += box_mask(UV,vec4(0.698,0.447,0.774,0.493));
    float dark_panes = 1.0-smoothstep(0.16,0.34,brightness);
    float far_light = town_layer*town_windows*dark_panes*window_light*0.65;
    color = mix(color,vec3(0.87,0.70,0.42),far_light);
    float rim = max(0.0,base.a-texture(TEXTURE,coord-vec2(TEXTURE_PIXEL_SIZE.x*2.0,TEXTURE_PIXEL_SIZE.y*2.0)).a);
    float lit_material = smoothstep(0.66,0.94,brightness);
    color += mix(wash_color.rgb,light_tint.rgb,0.6)*(rim*0.045+lit_material*0.018)*window_light;
    COLOR = vec4(color,base.a);
}
