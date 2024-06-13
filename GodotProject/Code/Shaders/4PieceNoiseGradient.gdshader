shader_type spatial;

render_mode world_vertex_coords;

uniform vec3 color1: source_color;
uniform vec3 color2: source_color;
uniform vec3 color3: source_color;
uniform vec3 color4: source_color;

uniform float color1_threshold = 0.0;
uniform float color2_threshold = 0.0;
uniform float color3_threshold = 0.0;
uniform float color4_threshold = 0.0;

uniform sampler2D noise_texture: filter_nearest;

uniform float transition_space = 10.0;

varying vec3 pos;

void vertex() {
	// Called for every vertex the material is visible on.
	pos = VERTEX;
}

vec3 mix_noise(vec3 col1, vec3 col2, float x, float ratio) {
	if(textureLod(noise_texture, vec2(x, ratio), 0).r < ratio) {
		return col2;
	} else {
		return col1;
	}
	return mix(col1, col2, ratio);
}

vec3 mix_noise2(vec3 col1, vec3 col2, float x, float ratio) {
	if(textureLod(noise_texture, vec2(x, ratio) * 0.1, 0).r < ratio) {
		return col2;
	} else {
		return col1;
	}
	return mix(col1, col2, ratio);
}

void fragment() {
	float dist_squared = pos.x*pos.x + pos.z*pos.z;
	float angle;
	float x = floor(pos.x * 4.0) / 4.0;
	float z = floor(pos.z * 4.0) / 4.0;
	if(pos.x == 0.0) {
		angle = 0.0;
	} else {
		angle = 100.0 * (atan(z / x) / (PI * 2.0));
	}
	//angle += pos.y / 500.0;
	vec3 result = COLOR.rgb;
	float size = 0.1;
	float y = pos.y + -40.0 + (sin(pos.x * size) * 5.0) - (cos(pos.z * size) * 5.0);
	y = mod(y, color4_threshold + transition_space);
	if(y < color1_threshold) {
		result = color1;
	} else if(y < color1_threshold + transition_space) {
		result = mix_noise(color1, color2, angle, (y - color1_threshold) / transition_space);
	} else if(y < color2_threshold) {
		result = color2;
	} else if(y < color2_threshold + transition_space) {
		result = mix_noise(color2, color3, angle, (y - color2_threshold) / transition_space);
	} else if(y < color3_threshold) {
		result = color3;
	} else if(y < color3_threshold + transition_space) {
		result = mix_noise(color3, color4, angle, (y - color3_threshold) / transition_space);
	} else if(y < color4_threshold) {
		result = color4;
	} else if(y < color4_threshold + transition_space) {
		result = mix_noise(color4, color1, angle, (y - color4_threshold) / transition_space);
	} else {
		result = color1;
	}

	float ySize = 20.0;
	float y2 = pos.y;
	float ratio2 = 20.0;
	y2 = mod(y, ratio2);
	if(textureLod(noise_texture, vec2(angle / 5.0, y2 / ratio2) * 1.0, 0).r < 0.5) {
		if(result == color1) result = color2;
		else if(result == color2) result = color3;
		else if(result == color3) result = color4;
		else if(result == color4) result = color1;
	}

	float threshold1 = 120.0*120.0;
	float threshold2 = 300.0*300.0;
	if(dist_squared > threshold1) {
		result = mix(result, vec3(0, 0, 0), 0.2 + ((dist_squared - threshold1) / threshold2));
	}

	result = mix(result, vec3(0, 0, 0), 0.5);

	if(pos.y < -10.0) {
		result = mix(result, vec3(0, 0, 0), (-pos.y - 10.0) / 25.0);
	}

	if(pos.y < 10.0) {
		result = mix(result, vec3(0.0, 0.1, 0.2), (pos.y - 10.0) / 40.0);
	}

	ALBEDO = result;
}
