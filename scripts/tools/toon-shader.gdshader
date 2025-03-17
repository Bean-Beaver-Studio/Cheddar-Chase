shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
}

void light() {
	float cNdotL = max(0.0, dot(NORMAL, LIGHT_DIRECTION));
	float toon = 0.0;
	if (cNdotL < 0.3) {
		toon = 0.0;
	} else if (cNdotL < 0.4) {
		toon = 0.5;
	} else {
		toon = 1.0;
	}
	LIGHT = vec4(LIGHT_COLOR.rgb * COLOR.rgb * LIGHT_ENERGY * toon, LIGHT_COLOR.a);
}
