extends LoadNode

func _enter_tree() -> void:
	start.connect(_instance_trees)

func generate_clump_on_central_point(central_point: Vector2, amount: int = 5, max_range: float = 5.0, max_offset: float = 1.0) -> Array[Vector2]:
	var clump_pos_array = [] as Array[Vector2]
	
	var grids_per_side = amount
	var grid_scale = max_range / grids_per_side
	grid_scale *= 2.0
	
	max_offset = max_offset / 2
	
	for x in grids_per_side:
		for y in grids_per_side:
			randomize()
			var pos = Vector2(x * grid_scale, y * grid_scale)
			pos += Vector2(randf_range(-max_offset,max_offset),randf_range(-max_offset,max_offset))
			pos += central_point
			
			if central_point.distance_to(pos) < 2.0:
				continue
			
			clump_pos_array.append(pos)
	
	var new_clump_pos_array = [] as Array[Vector2]
	for i in amount:
		randomize()
		var this_pos = clump_pos_array.pick_random()
		new_clump_pos_array.append(this_pos)
		clump_pos_array.erase(this_pos)
	
	return new_clump_pos_array

func get_tree_height(pos: Vector2, pixel_factor: float, heightmap: Image, height_scale: float = 90.0):
	var X: int = round(pos.x * pixel_factor + 512)
	var Y: int = round(pos.y * pixel_factor + 512)
	X = clamp(X,0,1023)
	Y = clamp(Y,0,1023)
	var height_val = heightmap.get_pixel(X,Y).r
	height_val *= height_scale
	if height_val <= 50:
		return 0
	return height_val

func _instance_trees():
	var base_pos_array = [] as Array[Vector2]
	
	#Grid Creation
	const MAP_SIZE: int = 2048
	const GRID_CHUNKS_PER_SIDE: int = 102
	
	var GRID_LENGTH = float(MAP_SIZE) / float(GRID_CHUNKS_PER_SIDE)
	var GRID_LENGTH_HALVED = GRID_LENGTH / 2.0
	
	for y in GRID_CHUNKS_PER_SIDE:
		for x in GRID_CHUNKS_PER_SIDE:
			randomize()
			var pos = Vector2(x * GRID_LENGTH, y * GRID_LENGTH) as Vector2
			pos += Vector2(GRID_LENGTH_HALVED,GRID_LENGTH_HALVED)
			pos += Vector2(randf_range(-GRID_LENGTH_HALVED,GRID_LENGTH_HALVED),randf_range(-GRID_LENGTH_HALVED,GRID_LENGTH_HALVED))
			pos -= Vector2.ONE * MAP_SIZE / 2
			base_pos_array.append(pos)
	#Tree Creation
	var HEIGHTMAP = load("res://resources/material/textures/heightmaps/island_heightmap.exr") as Texture2D
	var HEIGHTMAP_IMG = HEIGHTMAP.get_image()
	var PIXEL_FACTOR = float(HEIGHTMAP_IMG.get_width()) / float(MAP_SIZE)
	
	var TREE = load("res://resources/models/export/glb/objects/tree/tree.glb") as PackedScene
	var TREE_2 = load("res://resources/models/export/glb/objects/tree/tree_2.glb") as PackedScene
	var TREE_3 = load("res://resources/models/export/glb/objects/tree/tree_3.glb") as PackedScene
	var TREE_MODEL_ARRAY = [TREE, TREE_2, TREE_3] as Array[PackedScene]
	
	const BASE_TREE_COUNT: int = 5000
	
	for i in BASE_TREE_COUNT:
		randomize()
		
		var rand_pos = base_pos_array.pick_random() as Vector2
		var this_pos = Vector3.ZERO
		this_pos.x = rand_pos.x
		this_pos.z = rand_pos.y
		
		this_pos.y = get_tree_height(Vector2(this_pos.x,this_pos.z), PIXEL_FACTOR, HEIGHTMAP_IMG, 90.0)
		if this_pos.y <= 0:
			continue
		
		var this_tree_model = TREE_MODEL_ARRAY.pick_random() as PackedScene
		var this_tree = this_tree_model.instantiate() as Node3D
		
		WorldData.TREES_ROOT_NODE.add_child(this_tree)
		this_tree.global_position = this_pos
		
		if randf_range(0.0,1.0)<0.4:
			var clump_amount = randf_range(0,1)
			if clump_amount < 0.6:
				clump_amount = 4
			elif clump_amount < 0.8:
				clump_amount = 6
			elif clump_amount < 0.9:
				clump_amount = 8
			elif  clump_amount < 0.96:
				clump_amount = 10
			elif clump_amount <= 1.0:
				clump_amount = 12
			var clump_pos_array = generate_clump_on_central_point(rand_pos, clump_amount, 8, 2)
			for pos in clump_pos_array:
				randomize()
				
				this_pos = Vector3.ZERO
				this_pos.x = pos.x
				this_pos.z = pos.y
				
				this_pos.y = get_tree_height(Vector2(this_pos.x,this_pos.z), PIXEL_FACTOR, HEIGHTMAP_IMG, 90.0)
				
				this_tree_model = TREE_MODEL_ARRAY.pick_random() as PackedScene
				this_tree = this_tree_model.instantiate() as Node3D
				
				WorldData.TREES_ROOT_NODE.add_child(this_tree)
				this_tree.global_position = this_pos
	
	completed = true
