shader_type canvas_item;
render_mode unshaded;

uniform float motion_time = 0.0;
uniform float motion_amount = 1.0;
uniform int effect_kind = 0;
uniform vec4 light_color : source_color = vec4(0.47, 0.91, 0.78, 1.0);
uniform float seed = 0.0;

void fragment() {
    vec2 p = UV;
    float t = motion_time;
    vec3 color = light_color.rgb;
    float a = 0.0;
    if (effect_kind == 0) {
        // Three broad, continuously flowing curtains, with fine vertical rays.
        for (int band = 0; band < 3; band++) {
            float b = float(band);
            float curve = 0.24 + b * 0.18 + sin(p.x * 8.2 + t * 0.11 + b * 1.5) * 0.105;
            curve += sin(p.x * 18.0 - t * 0.16 + b) * 0.035 * motion_amount;
            float d = p.y - curve;
            float ribbon = exp(-abs(d) * 30.0);
            float curtain = smoothstep(-0.22, -0.015, d) * (1.0 - smoothstep(-0.018, 0.015, d));
            float rays = 0.49 + 0.51 * pow(0.5 + 0.5 * sin(p.x * 240.0 + sin(p.x * 31.0 + t * 0.31) * 3.0), 2.0);
            a += ribbon * 0.37 + curtain * rays * 0.20;
        }
        color = mix(vec3(0.42, 0.90, 0.69), vec3(0.66, 0.52, 0.88), smoothstep(0.2, 0.85, p.y));
        a *= smoothstep(0.0, 0.09, p.x) * (1.0 - smoothstep(0.87, 1.0, p.x));
    } else if (effect_kind == 1) {
        // Thin waterfalls travel downward rather than moving the entire island.
        float stream = exp(-pow((p.x - 0.5 + sin(p.y * 18.0 + t * 0.9) * 0.035) * 7.0, 2.0));
        float streak = 0.45 + 0.55 * pow(0.5 + 0.5 * sin(p.y * 65.0 - t * 6.5), 2.0);
        a = stream * streak * (1.0 - smoothstep(0.60, 1.0, p.y)) * 0.45;
    } else if (effect_kind == 2) {
        float distance_from_center = length((p - 0.5) * 2.0);
        a = exp(-distance_from_center * distance_from_center * 5.5) * 0.20;
        a *= 0.93 + sin(t * 0.35 + seed) * 0.07 * motion_amount;
    } else if (effect_kind == 3) {
        // Soft moving fog veils the foundations of the sunken city.
        float bands = 0.5 + 0.5 * sin(p.x * 13.0 - t * 0.20 + sin(p.x * 37.0 + t * 0.13));
        float vertical = exp(-pow((p.y - 0.55 + bands * 0.12) * 4.8, 2.0));
        a = vertical * (0.09 + bands * 0.09);
        a *= smoothstep(0.0, 0.1, p.x) * (1.0 - smoothstep(0.85, 1.0, p.x));
    } else if (effect_kind == 4) {
        // Small elliptical ripples around the rising ruins, not a whole-river warp.
        vec2 q = (p - 0.5) * vec2(1.0, 2.8);
        float r = length(q);
        float wave = 0.5 + 0.5 * sin(r * 65.0 - t * 1.6);
        a = pow(wave, 12.0) * exp(-r * 3.6) * 0.15;
        a *= smoothstep(0.0, 0.2, r);
    }
    COLOR *= vec4(color, a);
}
