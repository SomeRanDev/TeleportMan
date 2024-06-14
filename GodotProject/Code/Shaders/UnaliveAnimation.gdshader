shader_type canvas_item;

// 0 = unalive
// 1 = transition in
uniform int animationMode = 0;
uniform float animationRatio = 0.0;

// unalive
uniform sampler2D noise : repeat_enable;
uniform vec3 startColor : source_color;
uniform vec3 endColor : source_color;

// transition in
uniform sampler2D mask : repeat_disable;
uniform int transitionInType = 0;

//void vertex() {
	//// Called for every vertex the material is visible on.
//}

float easeOut(float v) {
	return v * v * v;
	v = 1.0 - v;
	return 1.0 - (v * v * v);
}

// https://forum.godotengine.org/t/how-to-rotate-a-uv-on-itself-instead-of-the-world-origin-in-world-triplanar-mode/12335/3
mat2 get2dRotationMatrix(float angleRadians) {
	float s = sin(angleRadians);
	float c = cos(angleRadians);
	return mat2(vec2(c, s), vec2(-s, c));
}

void fragment() {
	if(animationRatio > 0.0) {
		if(animationMode == 0) {
			float threshold = (1.0 - UV.y) + (((1.0 - (animationRatio / 0.666)) * 2.0) - 1.0);
			vec4 pixel = texture(noise, UV + vec2(TIME * 0.04, TIME * 0.08));
			COLOR.a = pixel.r < threshold ? 0.0 : 1.0;
			COLOR.rgb = mix(
				mix(startColor, endColor, pixel.g),
				vec3(0, 0, 0),
				easeOut(pixel.r - threshold)
			);
		} else if(animationMode == 1) {
			vec2 uv = UV;
			uv.x *= (1920.0 / 1080.0);
			if(transitionInType == 0) {
				uv += vec2(-0.4, 0.0);
			}
			uv -= vec2(0.5, 0.5);
			uv *= get2dRotationMatrix(radians(animationRatio * 270.0));
			uv += vec2(0.5, 0.5);
			if(transitionInType == 1) {
				uv += vec2(-0.4, 0.0);
			} else if(transitionInType == 2) {
				uv += vec2(0.8, 0.0);
			}

			// The following is based on:
			// https://www.youtube.com/watch?v=zwjdy20ArEM
			float s = pow(2.0, 10.0 * animationRatio - 10.0);
			int cutoff = int(s);
			s *= 75.0;
			vec2 offset = vec2(0.5, 0.5) * (1.0 - s);
			float alphaPixel = texture(mask, uv * s + offset).a;
			COLOR.a = 1.0 - alphaPixel + float(cutoff);
		}
	} else {
		COLOR.a = 0.0;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
