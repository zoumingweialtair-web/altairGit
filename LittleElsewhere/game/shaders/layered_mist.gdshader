shader_type canvas_item;
render_mode unshaded;
uniform float clock = 0.0;
uniform float density = 0.0;
uniform vec4 mist_color : source_color = vec4(0.75,0.83,0.81,1.0);
void fragment() {
    float band_a = exp(-pow((UV.y-(0.448+sin(UV.x*7.0+clock*0.07)*0.018))/0.048,2.0));
    float band_b = exp(-pow((UV.y-(0.515+sin(UV.x*9.0-clock*0.05)*0.014))/0.026,2.0));
    float grain = 0.68+0.16*sin(UV.x*23.0+UV.y*53.0+clock*0.13)+0.12*sin(UV.x*41.0-clock*0.18);
    float alpha = clamp((band_a+band_b*0.45)*grain*density,0.0,0.86);
    COLOR = vec4(mist_color.rgb,alpha);
}
