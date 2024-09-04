shader_type spatial;
render_mode depth_draw_always, diffuse_burley, blend_mix, ensure_correct_normals, vertex_lighting, shadows_disabled;

uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, filter_nearest, repeat_disable;

group_uniforms Color;
uniform vec3 albedo1: source_color;
uniform float albedo_screen_ratio = 0.5;
uniform float metallic: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float specular: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float roughness: hint_range(0.0, 1.0, 0.01) = 1.0;

group_uniforms Textures;
uniform sampler2D wave_strength_mask: hint_default_white, repeat_disable;
uniform sampler2D wave_noise_one;
uniform sampler2D wave_noise_one_normal_map: filter_nearest_mipmap, hint_normal, repeat_enable;
uniform sampler2D wave_noise_two;
uniform sampler2D wave_noise_two_normal_map: filter_nearest_mipmap, hint_normal, repeat_enable;
uniform sampler2D water_foam_tex: filter_nearest, repeat_enable;

group_uniforms Uv;
uniform float uv_scale;
uniform float world_size;
uniform float terrain_height;

group_uniforms WaveParams;
uniform float wave_speed = 0.01;
uniform float wave_height = 10.0;
uniform vec2 foam_range = vec2(1.3,0.6);
uniform vec2 wave_depth_strength_range = vec2(150,200);

varying vec2 og_world_pos;
varying vec2 world_pos;
varying vec2 world_pos_two;
varying float water_depth;
varying float dist;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest, repeat_disable;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	og_world_pos = world_pos;
	world_pos_two = world_pos;

	vec2 world_camera = INV_VIEW_MATRIX[3].xz;
	dist = distance(og_world_pos, world_camera);

	water_depth = abs(1.0 - textureLod(wave_strength_mask, (og_world_pos / world_size) + 0.5, 0.0).r)*terrain_height;
	water_depth = smoothstep(wave_depth_strength_range.x, wave_depth_strength_range.y, water_depth);

	float time_dilated = TIME * wave_speed;

	world_pos += time_dilated;
	world_pos *= uv_scale;

	world_pos_two -= time_dilated*0.25;
	world_pos_two *= uv_scale;

	float height_val = textureLod(wave_noise_one, world_pos, 0.0).r*water_depth;
	height_val = mix(height_val, textureLod(wave_noise_two, world_pos_two, 0.0).r*water_depth, 0.5);

	height_val = height_val * 2.0 - 1.0;
	height_val *= wave_height;

	height_val *= clamp(water_depth, 0.15, 1.0);

	VERTEX.y += height_val;
}

float is_edge(vec2 pix_offset, vec2 viewport_size, vec2 screen_uv, mat4 inv_proj, float vert) {
	vec2 iuv = vec2(screen_uv.x * viewport_size.x, screen_uv.y * viewport_size.y);
	float neighbor_depth = texture(DEPTH_TEXTURE, (iuv + vec2(pix_offset.x, pix_offset.y)) / viewport_size).x;
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, neighbor_depth);
	vec4 view = inv_proj * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float new_lin_depth = -view.z;
	new_lin_depth = vert + new_lin_depth;
	return step(2.0, new_lin_depth);
}

void fragment() {
	//BASIC CONSTANTS//////////
	ALBEDO = albedo1;
	METALLIC = metallic;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	///////////////////////////

	//FOAM
	float height_val_two = textureLod(wave_noise_one, world_pos, 0.0).r;
	height_val_two = mix(height_val_two, textureLod(wave_noise_two, world_pos_two, 0.0).r, 0.5);

	height_val_two = height_val_two * 2.0 - 1.0;
	height_val_two *= wave_height;

	height_val_two *= clamp(water_depth, 0.15, 1.0);

	float dist_mask = clamp(abs(pow(smoothstep(350.0, 1000.0,dist),0.25)), 0.0,0.75);

	ALBEDO = mix(mix(vec3(1.0),ALBEDO,smoothstep(foam_range.x,foam_range.y,height_val_two)), ALBEDO, dist_mask);

	//DEPTH STUFF - OBJECT FOAM, UNDERWATER DARKNESS//////////
	vec2 pix_screen_uv = round(SCREEN_UV * float(1920.0)) / float(1920.0);

	float depth = texture(DEPTH_TEXTURE, pix_screen_uv).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	linear_depth = VERTEX.z + linear_depth;

	if (step(0.5, linear_depth) != 1.0) {
		linear_depth += 1000.0 * is_edge(vec2(-1.0, 0.0), VIEWPORT_SIZE, SCREEN_UV, INV_PROJECTION_MATRIX, VERTEX.z);
		linear_depth += 1000.0 * is_edge(vec2(1.0, 0.0), VIEWPORT_SIZE, SCREEN_UV, INV_PROJECTION_MATRIX, VERTEX.z);
		linear_depth += 1000.0 * is_edge(vec2(0.0, -1.0), VIEWPORT_SIZE, SCREEN_UV, INV_PROJECTION_MATRIX, VERTEX.z);
		linear_depth += 1000.0 * is_edge(vec2(0.0, 1.0), VIEWPORT_SIZE, SCREEN_UV, INV_PROJECTION_MATRIX, VERTEX.z);
		//linear_depth += 1000.0 * is_edge(vec2(-1.0, -1.0), VIEWPORT_SIZE, SCREEN_UV, INV_PROJECTION_MATRIX, VERTEX.z);
		//linear_depth += 1000.0 * is_edge(vec2(1.0, -1.0), VIEWPORT_SIZE, SCREEN_UV, INV_PROJECTION_MATRIX, VERTEX.z);
	}
	if (linear_depth<-1.0) {
		linear_depth += 1000.0;
	}

	//OBJECT FOAM
	float foam_color = texture(water_foam_tex, (og_world_pos/70.0 + TIME/100.0)).r;
	vec3 foam_color_rgb = mix(ALBEDO, vec3(foam_color), foam_color);
	foam_color_rgb = mix(foam_color_rgb, vec3(1.0), smoothstep(.2, -0.1, linear_depth));

	ALBEDO = mix(foam_color_rgb,ALBEDO, clamp(smoothstep(-1.0, 3.0, linear_depth), 0.0, 1.0));

	linear_depth *= 0.0002;
	linear_depth = smoothstep(0.0003,0.0025,linear_depth);
	linear_depth = pow(1.8, linear_depth);

	ALBEDO *= vec3(linear_depth);
	//////////////////////////////////////////////////////////

	//WATER NORMALS
	vec3 normal = texture(wave_noise_one_normal_map, world_pos).xyz;
	normal = mix(normal, texture(wave_noise_two_normal_map, world_pos_two).xyz, 0.5);

	NORMAL_MAP = normal;
	NORMAL_MAP_DEPTH = 1.0;

	NORMAL_MAP_DEPTH *= clamp(water_depth, 0.15, 1.0);

	//SEE THROUGH WATER EFFECT.
	vec3 screen_tex = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	float ratio = smoothstep(5.0,500.0,dist);
	ratio = mix(ratio, 1.0, smoothstep(-0.5, 1.5, linear_depth));

	ALBEDO = mix(screen_tex, ALBEDO, clamp(ratio,albedo_screen_ratio,1.0));
	//ALBEDO = vec3(SCREEN_UV.x * SCREEN_UV.y,ALBEDO.g,ALBEDO.b);
}