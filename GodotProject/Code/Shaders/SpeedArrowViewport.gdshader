shader_type canvas_item;

uniform float opacity = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if(COLOR.g > 0.8 && COLOR.r > 0.8 && COLOR.b > 0.8) {
		COLOR.a = 0.0;
	}
	COLOR.a *= opacity;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
