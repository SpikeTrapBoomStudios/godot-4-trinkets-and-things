shader_type spatial;
render_mode cull_back, unshaded, vertex_lighting;

uniform sampler2D displace_texture: repeat_disable, hint_default_black, filter_linear;
uniform float displace_multi = 20.0;
uniform float world_size;
uniform sampler2D normal_texture: repeat_disable, hint_default_black, filter_linear;
uniform sampler2D color_ramp: repeat_disable;
uniform sampler2D color_noise: repeat_enable;
uniform sampler2D scale_noise: repeat_enable;

uniform float fade_min = 20.0;
uniform float fade_max = 20.0;
uniform float start;
uniform float end;

varying vec2 world_pos;
varying float dist;

void vertex() {
	world_pos = MODEL_MATRIX[3].xz/150.0;

	vec2 world_uv = (MODEL_MATRIX[3].xz)/world_size;
	world_uv += 0.5;
	float displace_val = textureLod(displace_texture,world_uv,1.0).r * displace_multi;
	VERTEX.y += displace_val;

	vec3 world_camera = INV_VIEW_MATRIX[3].xyz;
	dist = distance(MODEL_MATRIX[3].xyz, world_camera);

	float scale_factor = textureLod(scale_noise, MODEL_MATRIX[3].xz, 0.0).r * 2.0;
	scale_factor *= smoothstep(45, 60, displace_val);

	vec3 normal_map = texture(normal_texture,world_uv).xyz;
	float slope = normal_map.x*normal_map.y*normal_map.z;
	scale_factor *= smoothstep(0.1,0.3,slope);

	VERTEX.xyz *= scale_factor;
	VERTEX.y -= displace_val * (scale_factor - 1.0);
	VERTEX.y -= NODE_POSITION_WORLD.y;
}

void fragment() {
	ALBEDO = vec3(1.0);
	ALBEDO *= texture(color_noise,world_pos).rgb;
	ALBEDO *= texture(color_ramp,vec2(abs(1.0 - UV.y),0.0)).rgb;

	ALPHA *= smoothstep(fade_max,fade_min,dist);
	ALPHA *= smoothstep(start,end,dist);
	ALPHA_HASH_SCALE = 1.0;
}
