// NOTE: Shader automatically converted from Godot Engine 4.3.beta1's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, unshaded;

uniform sampler2D _view_texture : source_color, filter_linear_mipmap, repeat_enable;

void vertex() {
}

void fragment() {
	ALBEDO = texture(_view_texture, SCREEN_UV).rgb;
}
