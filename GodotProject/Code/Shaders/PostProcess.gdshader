shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest_mipmap;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float px = 0.5/VIEWPORT_SIZE.x;
	float py = 0.5/VIEWPORT_SIZE.y;
	
	float diff = 15.0;
	float d = floor(texture(SCREEN_TEXTURE, SCREEN_UV).r * diff) / diff;
	float du = floor(texture(SCREEN_TEXTURE, SCREEN_UV+vec2(0.0, py)).r * diff) / diff;
	float dd = floor(texture(SCREEN_TEXTURE, SCREEN_UV+vec2(0.0, -py)).r * diff) / diff;
	float dr = floor(texture(SCREEN_TEXTURE, SCREEN_UV+vec2(px, 0.0)).r * diff) / diff;
	float dl = floor(texture(SCREEN_TEXTURE, SCREEN_UV+vec2(-px, 0.0)).r * diff) / diff;
	
	ALPHA = (
		abs(abs(d)-abs(du)) +
		abs(abs(d)-abs(dd)) +
		abs(abs(d)-abs(dl)) +
		abs(abs(d)-abs(dr))
	);
			
	ALPHA *= 100.0*4.0;
	ALPHA *= 0.02;
	
	ALBEDO = vec3(0.0, 0.0, 0.0);//.rgb;
	//ALPHA = 0.0;
}
