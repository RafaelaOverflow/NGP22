shader_type spatial;

//render_mode unshaded;

uniform sampler2D tex : filter_nearest;
instance uniform vec3 light_normal = vec3(0.0,0.0,1.0);
varying vec3 vert;

void vertex() {
	vert = (MODEL_MATRIX*vec4(NORMAL,0.0)).xyz;
}

void fragment() {
	ALBEDO = texture(tex,UV).xyz;
	//ALBEDO *= 0.9;
	//ALBEDO *= clamp(dot(vert, light_normal), 0.05, 1.0) * vec3(1.0);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
