shader_type spatial;
render_mode depth_draw_always, diffuse_burley, cull_back, blend_mix, ensure_correct_normals, vertex_lighting;

uniform sampler2D DEPTH_TEXTURE: hint_depth_texture;

group_uniforms Color;
uniform vec3 albedo1: source_color;
uniform float metallic: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float specular: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float roughness: hint_range(0.0, 1.0, 0.01) = 1.0;

group_uniforms Textures;
uniform sampler2D wave_strength_mask: hint_default_white, repeat_disable;
uniform sampler2D wave_noise_one;
uniform sampler2D wave_noise_one_normal_map: filter_linear_mipmap, hint_normal, repeat_enable;
uniform sampler2D wave_noise_two;
uniform sampler2D wave_noise_two_normal_map: filter_linear_mipmap, hint_normal, repeat_enable;

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

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	og_world_pos = world_pos;
	world_pos_two = world_pos;

	world_pos += TIME*wave_speed;
	world_pos *= uv_scale;

	world_pos_two -= TIME*wave_speed*0.25;
	world_pos_two *= uv_scale;
}

void fragment() {

	//BASIC CONSTANTS//////////
	ALBEDO = albedo1;
	METALLIC = metallic;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	///////////////////////////

	//FOAM
	float height_val = textureLod(wave_noise_one, world_pos, 0.0).r;
	height_val = mix(height_val, textureLod(wave_noise_two, world_pos_two, 0.0).r, 0.5);

	height_val = height_val * 2.0 - 1.0;
	height_val *= wave_height;

	float water_depth = texture(wave_strength_mask, (og_world_pos / world_size) + 0.5).r*terrain_height;
	water_depth = abs(1.0 - pow(smoothstep(wave_depth_strength_range.x, wave_depth_strength_range.y, water_depth),1.0));
	height_val *= clamp(water_depth, 0.15, 1.0);

	ALBEDO = mix(mix(vec3(1.0),ALBEDO,smoothstep(foam_range.x,foam_range.y,height_val)), ALBEDO, 0.75);

	ALBEDO *= vec3(1.8);
	//////////////////////////////////////////////////////////

	//WATER NORMALS
	vec3 normal = texture(wave_noise_one_normal_map, world_pos).xyz;
	normal = mix(normal, texture(wave_noise_two_normal_map, world_pos_two).xyz, 0.5);

	NORMAL_MAP = normal;
	NORMAL_MAP_DEPTH = 1.0;

	NORMAL_MAP_DEPTH *= clamp(water_depth, 0.15, 1.0);
}