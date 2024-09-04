extends LoadNode

const vectors_file_path: String = "res://assets/init_assets/foliage_instance_data/grass_vectors.res"
const multimesh_file_path: String = "res://assets/init_assets/foliage_instance_data/multimesh_data/"

func _enter_tree() -> void:
	start.connect(_instance_trees)

func _instance_trees():
	var grass_material: ShaderMaterial = load("res://resources/material/shader/grass.tres")
	var grass_two_material: ShaderMaterial = load("res://resources/material/shader/grass_two.tres")
	#var grass_three_material: ShaderMaterial = load("res://resources/material/shader/grass_three.tres")
	var grass_default_mesh: Resource = load("res://assets/init_assets/foliage_instance_data/grass_mesh_default.multimesh")
	var grass_half_model: Resource = load("res://resources/models/export/obj/foliage/grass_flat_half.obj")
	
	var grass_two_mesh = grass_default_mesh.duplicate()
	grass_two_mesh.visible_instance_count = round(grass_default_mesh.visible_instance_count / 3.0)
	grass_two_mesh.mesh = grass_half_model
	
	var file = FileAccess.open(vectors_file_path,FileAccess.READ)
	var vectors: Array[Vector3] = str_to_var(file.get_as_text()) as Array
	file.close()
	
	for i in vectors.size():
		progress_percent = round(float(i) / float(vectors.size()) * 100.0)
		var new_grass = MultiMeshInstance3D.new()
		
		WorldData.FOLIAGE_ROOT_NODE.add_child(new_grass)
		new_grass.owner = WorldData.FOLIAGE_ROOT_NODE
		new_grass.global_position = vectors[i]
		
		new_grass.multimesh = grass_default_mesh
		new_grass.material_override = grass_material
		new_grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		new_grass.custom_aabb = AABB(Vector3(-25.5,-12.5,-25.5),Vector3(51.0,25,51.0))
		new_grass.visibility_range_end = 60.0
		new_grass.name = "Grass" + str(i)
		
		var grass_two = new_grass.duplicate() as MultiMeshInstance3D
		grass_two.multimesh = grass_two_mesh
		grass_two.material_override = grass_two_material
		grass_two.visibility_range_end = 170
		new_grass.add_child(grass_two)
		grass_two.owner = WorldData.FOLIAGE_ROOT_NODE
		grass_two.name = "GrassTwo"
		grass_two.global_transform = new_grass.global_transform
		
		if i % 500 == 0: await get_tree().process_frame
	#files = null
	
	'var saved_grass = PackedScene.new()
	saved_grass.pack(WorldData.FOLIAGE_ROOT_NODE)
	ResourceSaver.save(saved_grass, "res://grass_export.scn")'
	
	completed = true
