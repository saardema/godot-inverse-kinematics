shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform float uv_scale = 10.;
uniform float checkerboard_mix : hint_range(0.0, 1.0) = 1.;
uniform float roughness : hint_range(0.0, 1.0);
uniform float metallic : hint_range(0.0, 1.0);
uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float distance_fade_min : hint_range(0.0, 4096.0, 0.01);
uniform float distance_fade_max : hint_range(0.0, 4096.0, 0.01);
uniform vec4 albedo : source_color = vec4(1.);

void fragment() {
	SPECULAR = specular;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	ALBEDO = albedo.rgb;
	ALPHA *= albedo.a;

	// Checkerboard
  	float fmodResult = mod(floor(uv_scale * UV.x) + floor(uv_scale * UV.y), 2.0);
	float checkerboard = max(sign(fmodResult), 0.0);
	ALBEDO *= mix(vec3(checkerboard), vec3(1.), 1. - checkerboard_mix);

	// Distance Fade: Pixel Alpha
	ALPHA *= clamp(smoothstep(distance_fade_min, distance_fade_max, length(VERTEX)), 0.0, 1.0);
}
