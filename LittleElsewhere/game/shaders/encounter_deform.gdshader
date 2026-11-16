shader_type canvas_item;
render_mode unshaded;

uniform float motion_time = 0.0;
uniform float motion_amount = 1.0;
uniform int subject_kind = 0;
uniform float seed = 0.0;
varying vec4 subject_color;

void vertex() {
    subject_color = COLOR;
}

void fragment() {
    vec2 uv = UV;
    float t = motion_time;
    float lower = smoothstep(0.18, 0.95, UV.y);
    if (subject_kind == 1) {
        // The head stays steady while the lower tentacles gently shift.
        uv.x += sin(UV.y * 14.0 + t * 0.52 + seed) * 0.014 * lower * motion_amount;
        uv.y += sin(UV.x * 12.0 + t * 0.31) * 0.004 * motion_amount;
    } else if (subject_kind == 2) {
        // Jellyfish bells breathe; their long lower filaments move separately.
        uv.x += sin(UV.y * 23.0 - t * 1.1 + seed) * 0.021 * lower * motion_amount;
        uv.y += sin(UV.x * 9.0 + t * 0.7) * 0.005 * lower * motion_amount;
    } else if (subject_kind == 3) {
        // A restrained constellation gait, with most motion near the legs.
        uv.x += sin(UV.y * 13.0 + t * 0.9) * 0.008 * lower * motion_amount;
        uv.y += sin(UV.x * 17.0 + t * 1.3) * 0.005 * lower * motion_amount;
    } else if (subject_kind == 0) {
        uv.x += sin(UV.y * 12.0 + t * 0.19 + seed) * 0.008 * motion_amount;
        uv.y += sin(UV.x * 10.0 + t * 0.23 + seed) * 0.005 * motion_amount;
    }
    vec4 c = texture(TEXTURE, uv);
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) c.a = 0.0;
    if (subject_kind == 3) {
        float sparkle = 0.91 + 0.09 * sin(t * 1.45 + UV.x * 32.0 + UV.y * 19.0);
        c.rgb *= sparkle;
    }
    if (subject_kind == 4) c.a *= 1.0 - smoothstep(0.84, 0.99, UV.y);
    COLOR = subject_color * c;
}
