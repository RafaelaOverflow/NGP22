shader_type spatial;
render_mode cull_disabled;

uniform sampler2D ring_tex;
instance uniform float start = 1.0;
instance uniform float size = 1.0;
instance uniform vec3 color : source_color = vec3(1.0);

varying vec3 vec;

void vertex() {
	vec = VERTEX;
}

void fragment() {
	float d = distance(vec,vec3(0));
	ALBEDO = color;
	//ALPHA_SCISSOR_THRESHOLD = 0.1;
	if (d < start || d > (start+size)) {
		ALPHA = 0.0;
	}
	else{
		ALPHA = texture(ring_tex,vec2((d-start)/size,0)).x;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
