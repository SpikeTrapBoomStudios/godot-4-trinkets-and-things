shader_type spatial;
render_mode depth_draw_always, cull_back, blend_mix, ensure_correct_normals, vertex_lighting;

group_uniforms Textures;
uniform sampler2D displace_texture: repeat_disable, hint_default_black, filter_linear;
uniform float displace_multi = 20.0;
uniform sampler2D normal_texture: repeat_disable, hint_default_white, filter_linear;
uniform float normal_multi = 20.0;

group_uniforms Colors;
uniform vec3 sand_color: source_color;
uniform sampler2D sand_tex: source_color, filter_nearest_mipmap_anisotropic;
uniform vec3 grass_color: source_color;
uniform sampler2D grass_tex: source_color, filter_nearest_mipmap_anisotropic;
//uniform vec3 rock_color: source_color;
//uniform sampler2D rock_tex: source_color, filter_linear_mipmap_anisotropic;
//uniform sampler2D grass_color_mask: repeat_enable;
uniform sampler2D color_noise: repeat_enable, filter_nearest;

group_uniforms ColorHeights;
uniform float sand_height_max;
uniform float grass_height_min;
uniform float grass_height_max;
uniform float rock_height_min;

group_uniforms Uv;
uniform float world_size;

varying vec2 world_uv;
varying float height;
varying vec2 world_pos;
varying float dist;
varying float normal_y;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;

	world_uv = (world_pos)/world_size;
	world_uv += 0.5;

	float displace_val = textureLod(displace_texture,world_uv,1.0).r;
	displace_val *= displace_multi;
	height = displace_val;

	VERTEX.y = displace_val;

	vec3 world_camera = INV_VIEW_MATRIX[3].xyz;
	dist = distance((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz, world_camera);

	normal_y = NORMAL.y;
}

void fragment() {
	ALBEDO *= texture(color_noise,world_pos/150.0).rgb;

	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;

	vec2 world_uv_clamped = clamp(world_uv, vec2(0.0), vec2(1.0));

	/*vec3 grass_color_tex = texture(grass_color, world_pos).rgb;
	vec3 grass_color_mask_tex = pow(texture(grass_color_mask, world_pos / 150.0).rgb * 1.0,vec3(3.0));
	vec3 grass_color_overlay = mix(
		grass_color_mask_tex,
		grass_color_tex,
		clamp(smoothstep(200.0, 300.0, dist), 0.1, 0.8)
	);

	vec3 sand_color_overlay = texture(sand_tex, world_uv * 10.0).rgb;

	ALBEDO = mix(
				sand_color*sand_color_overlay,
				grass_color_tex*grass_color_overlay,
				smoothstep(sand_height_max,grass_height_min,height)
			);*/
	//ALBEDO *= vec3(pow(clamp(height, 30, 1000) / displace_multi, 2.0)) * 2.0;
	NORMAL_MAP = texture(normal_texture,world_uv).xyz;
	NORMAL_MAP_DEPTH = normal_multi;
	float slope = NORMAL_MAP.x*NORMAL_MAP.y*NORMAL_MAP.z;

	float dist_tex_fade = clamp(smoothstep(50.0,5.0,dist), 0.15, 1.0);

	vec3 grass_color_tex = texture(grass_tex, world_pos/8.0).rgb;
	ALBEDO = mix(grass_color,grass_color_tex,dist_tex_fade);

	vec3 sand_color_tex = texture(sand_tex, world_pos/8.0).rgb;
	vec3 sand_albedo = mix(sand_color,sand_color_tex,dist_tex_fade);
	ALBEDO = mix(sand_albedo, ALBEDO, smoothstep(sand_height_max,grass_height_min,height));

	//vec3 rock_color_tex = texture(rock_tex, world_pos/4.0).rgb;
	//vec3 rock_albedo = mix(rock_color,rock_color_tex,dist_tex_fade);
	//ALBEDO = mix(ALBEDO, rock_albedo, smoothstep(0.2,0.1,slope)*smoothstep(grass_height_max,rock_height_min,height));
}