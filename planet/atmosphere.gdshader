shader_type spatial;

instance uniform float a = 0.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALPHA = 0.1*a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
