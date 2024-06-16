shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	if(COLOR.a < 0.5) {
		COLOR.a = 0.0;
	} else {
		COLOR.a = 1.0;
		
		//float compress = 8.0;
		//COLOR.r = floor(COLOR.r * compress) / compress;
		//COLOR.g = floor(COLOR.g * compress) / compress;
		//COLOR.b = floor(COLOR.b * compress) / compress;
		
		COLOR.rgb *= 1.8;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
