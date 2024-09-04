shader_type spatial;
render_mode vertex_lighting, depth_prepass_alpha, cull_back;

uniform sampler2D displace_texture: repeat_disable, hint_default_black, filter_linear;
uniform float displace_multi = 20.0;
uniform float world_size;
uniform sampler2D normal_texture: repeat_disable, hint_default_black, filter_linear;
uniform sampler2D color_ramp: repeat_disable;
uniform sampler2D base_tex: repeat_disable;
uniform sampler2D wind_noise : hint_default_black;
uniform sampler2D color_noise: repeat_enable, filter_nearest;
uniform sampler2D scale_noise: repeat_enable;

uniform float wind_speed = 0.2;
uniform float wind_strength = 2.0;

uniform float min_dist = 10.0;
uniform float max_dist = 20.0;
uniform float start;
uniform float end;

varying vec2 world_pos;
varying float dist;
varying flat float scale_factor;

void vertex() {
	world_pos = MODEL_MATRIX[3].xz/150.0;

	vec2 world_uv = (MODEL_MATRIX[3].xz)/world_size;
	world_uv += 0.5;
	float displace_val = textureLod(displace_texture,world_uv,1.0).r * displace_multi;
	VERTEX.y += displace_val;

	vec2 uv = world_pos + (TIME * wind_speed);
	vec2 bump_wind = (textureLod(wind_noise, uv, 0.0).rg - 0.5) * wind_strength;

	VERTEX.xz += bump_wind * abs(1.0 - UV.y);

	scale_factor = pow(textureLod(scale_noise, MODEL_MATRIX[3].xz, 0.0).r, 1.15);
	float y_scale_factor = scale_factor / 8.0;
	scale_factor *= smoothstep(38, 45, displace_val);

	vec3 normal_map = texture(normal_texture,world_uv).xyz;
	float slope = normal_map.x*normal_map.y*normal_map.z;
	scale_factor *= smoothstep(0.05,0.12,slope);
	y_scale_factor *= smoothstep(0.2,0.3,scale_factor);

	VERTEX.xyz *= scale_factor;
	VERTEX.y += abs(1.0 - UV.y) * y_scale_factor;
	VERTEX.y -= displace_val * (scale_factor - 1.0);
	VERTEX.y -= NODE_POSITION_WORLD.y;

	vec3 world_camera = INV_VIEW_MATRIX[3].xyz;
	dist = distance((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz, world_camera);
}

float random(vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	ALBEDO *= texture(color_noise,world_pos).rgb;
	ALBEDO *= texture(color_ramp,vec2(abs(1.0 - UV.y),0.0)).rgb;

	ALPHA = texture(base_tex,UV).a;
	ALPHA *= smoothstep(max_dist,min_dist,dist);
	ALPHA *= smoothstep(start,end,dist);

	//ALPHA = ALPHA * mix(ALPHA, texture(base_tex,UV).a, smoothstep(min_dist, end, dist));
	ALPHA_HASH_SCALE = 1.0;
	BACKLIGHT = vec3(1.0);
}
