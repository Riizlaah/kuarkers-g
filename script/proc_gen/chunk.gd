class_name TerrainChunk
extends MeshInstance3D

class Tile extends Object:
	var pos: Vector3
	var biome: Biome
	var loc_pos: Vector3
	#var objects: Array = []
	func _init(tile_pos: Vector3, tile_biome: Biome):
		pos = tile_pos
		biome = tile_biome

const nature_res = preload("res://scene/proc_gen/nature_res.tscn")
const ctr_offset = 0.5
var resolution := Settings.lods[2]
var adj_terrain_h := 20
var chunk_size: int
var lods = Settings.lods
var lods_dist = Settings.lods_dist
var coord = Vector2()
var set_colls = false
var vertexes = []
var objects_loaded = false
var occupied_pos = {}
var texture_created := false
var tiles: Array[Tile]
var large_noise: FastNoiseLite
var small_noise: FastNoiseLite
var height_noise: FastNoiseLite
var load_fd := false
#var temperature_noise: FastNoiseLite
#var humidity_noise: FastNoiseLite
var biomes: Array[Biome]
var parent: TerrainGenerator

#objects in chunk
var trees = []
var grasses = []
var stones = []
var o_objs = []

func _init():
	#large_noise = noises[0]
	#small_noise = noises[1]
	#height_noise = noises[2]
	var mat = StandardMaterial3D.new()
	#mat.albedo_color = Color.WEB_GREEN
	mat.vertex_color_use_as_albedo = true
	material_overlay = mat

func _ready():
	parent = get_parent()
	large_noise = parent.large_noise
	small_noise = parent.small_noise
	height_noise = parent.height_noise
	biomes = get_parent().biomes
	lods = Settings.lods
	lods_dist = Settings.lods_dist
	set_process(false)
	set_physics_process(false)
	#var new_node = MeshInstance3D.new()
	#var new_node_mesh = BoxMesh.new()
	#new_node_mesh.size.y = 40
	#new_node.mesh = new_node_mesh
	#add_child(new_node)
	#RenderingServer.set_debug_generate_wireframes(true)
	#RenderingServer.viewport_set_debug_draw(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_DEBUG_DRAW_WIREFRAME)

#lfd = load from data
func gen_mesh(pos: Vector2, size: int, init_visible: bool, lfd: bool, flat: bool):
	var surf_tool = SurfaceTool.new()
	chunk_size = size
	coord = pos * size
	load_fd = lfd
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in resolution + 1:
		for x in resolution + 1:
			var percent = Vector2(x, z) / resolution
			var point_on_mesh = Vector3((percent.x - ctr_offset), 0, (percent.y - ctr_offset))
			var vertex = point_on_mesh * size
			var global_pos = Vector2(coord.x + vertex.x, coord.y + vertex.z)
			if is_nan(global_pos.x) or is_nan(global_pos.y): continue
			var biome = identify_biome(global_pos)
			if !flat: vertex.y = snappedf(get_biome_height_blended(global_pos), 1)
			if is_nan(vertex.y): continue
			surf_tool.set_color(biome.color)
			surf_tool.set_uv(percent)
			surf_tool.add_vertex(vertex)
			if !vertexes.has(vertex): vertexes.append(vertex)
			create_tile(vertex, biome)
			#print(vertex)
	var vert = 0
	for z in resolution:
		for x in resolution:
			surf_tool.add_index(vert)
			surf_tool.add_index(vert + 1)
			surf_tool.add_index(vert + resolution + 1)
			surf_tool.add_index(vert + resolution + 1)
			surf_tool.add_index(vert + 1)
			surf_tool.add_index(vert + resolution + 2)
			vert += 1
		vert += 1
	surf_tool.generate_normals()
	mesh = surf_tool.commit()
	create_colls()
	set_chunk_visible(init_visible)
	#if resolution > 0: create_texture()

func create_texture():
	var img = Image.create(resolution, resolution, true, Image.FORMAT_RGB8)
	for tile in tiles:
		var vect = vert_to_pix(tile.pos)
		if vect.y >= resolution or vect.x >= resolution: continue
		img.set_pixelv(vert_to_pix(tile.pos), tile.biome.color)
	#img.resize(resolution*4, resolution*4, Image.INTERPOLATE_NEAREST)
	var mat = StandardMaterial3D.new()
	var texr = ImageTexture.create_from_image(img)
	mat.albedo_texture = texr
	material_override = mat

func vert_to_pix(vert: Vector3) -> Vector2:
	var offset := resolution * 4
	var p_x := (vert.x + offset) / resolution
	var p_y := (vert.z + offset) / resolution
	#print(vert, resolution)
	return Vector2(p_x, p_y)

#kekurangan: belum terpengaruh oleh suatu bioma
#var height = height2_noise.get_noise2dv(pos) * adj_terrain_h
#var small = height2_noise.get_noise2dv(pos)
#var large = height2_noise.get_noise2dv(pos) * 16
# (small + large + height) * 8
#
func get_biome_height_blended(pos: Vector2) -> float:
	var base_height := 0.0
	var large = (large_noise.get_noise_2dv(pos) + 1) / 2
	base_height += parent.large_curve.sample(large)
	if large < 0.7: return base_height
	base_height *= 0.9
	var height := (height_noise.get_noise_2dv(pos) + 1) / 2
	base_height += parent.height_curve.sample(height)
	if height < 0.4: return base_height
	base_height *= 0.9
	var small = (small_noise.get_noise_2dv(pos) + 1) / 2
	return base_height + parent.small_curve.sample(small)

func identify_biome(pos: Vector2) -> Biome:
	var noise_val := large_noise.get_noise_2dv(pos)
	#print(noise_val)
	for biome in biomes:
		if biome.is_req_valid(noise_val): return biome
	return biomes[4]

func create_tile(pos: Vector3, biome: Biome):
	var tile = Tile.new(pos, biome)
	tiles.append(tile)
	if !load_fd: place_objects_in_tile(tile)

func place_objects_in_tile(tile: Tile):
	var percentage = randi_range(0, 1500)
	match tile.biome.name:
		'rocky': if percentage < 30: _spawn_stone(tile.pos)
		'grassland': if percentage < 90: _spawn_grass(tile.pos)
		'forest': if percentage < 40: _spawn_tree(tile.pos)
		'mountains': if percentage < 10: _spawn_stone(tile.pos)
		'hills': if percentage < 20: _spawn_tree(tile.pos)
		'high_mountains': if percentage < 10: _spawn_stone(tile.pos)

func load_datas(trees2, grasses2, stones2):
	for tree in trees2: _spawn_tree(tree.pos, tree.height)
	for grass in grasses2: _spawn_grass(grass.pos)
	for stone in stones2: _spawn_stone(stone.pos, stone.drop_count)
	#for obj in objs2:
		#place_object(objs2[obj].pos, objs2[obj].type)

func update_lod(view_pos: Vector2):
	var viewer_dist = coord.distance_to(view_pos)
	var update = false
	var new_lod = lods[0]
	for i in lods.size():
		if viewer_dist < lods_dist[i]: new_lod = lods[i]
	if new_lod >= lods[lods.size() - 1]: set_colls = true
	else: set_colls = false
	if resolution != new_lod:
		resolution = new_lod
		update = true
	return update

func update_chunk(view_pos: Vector2, max_dist):
	var viewer_dist = coord.distance_to(view_pos)
	var is_visib = viewer_dist <= (max_dist * 1.25)
	set_chunk_visible(is_visib)

func create_colls():
	if has_node("StaticBody3D"): get_node("StaticBody3D").queue_free()
	create_trimesh_collision()

func set_chunk_visible(visib: bool):
	var colls = get_node_or_null("StaticBody3D")
	if visib == true:
		show()
		if is_instance_valid(colls): colls.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		hide()
		if is_instance_valid(colls): colls.process_mode = Node.PROCESS_MODE_DISABLED

func reduce_slope(height: float, slope_factor: float) -> float:
	return height * (1.0 - slope_factor) + slope_factor * smoothstep(0.0, 1.0, height)

func get_saves():
	var loc_trees = []
	var loc_grasses = []
	var loc_stones = []
	var loc_objs = []
	for tree in trees:
		if !is_instance_valid(tree): continue
		loc_trees.append({"pos": tree.position, "height": tree.drop_count})
	for grass in grasses:
		if !is_instance_valid(grass): continue
		loc_grasses.append({'pos': grass.position})
	for stone in stones:
		if !is_instance_valid(stone): continue
		loc_stones.append({"pos": stone.position, "drop_count": stone.drop_count})
	for obj in o_objs:
		if !is_instance_valid(obj): continue
		loc_objs.append({"pos": obj.global_position, "type": obj.type})
	return [loc_trees, loc_stones, loc_grasses, loc_objs, coord]

func _spawn_tree(spawn_pos: Vector3, height: int = 0) -> void:
	var pos_key = Vector2i(Vector2(spawn_pos.x, spawn_pos.z))
	if occupied_pos.has(pos_key): return
	occupied_pos[pos_key] = true
	var new_tree = nature_res.instantiate()
	new_tree.res_type = NatureRes.ResType.TREE
	new_tree.drop_count = randi_range(2, 9) if height == 0 else height
	new_tree.position = spawn_pos
	add_child(new_tree)
	trees.append(new_tree)

func _spawn_stone(spawn_pos: Vector3, drop_count: int = 0):
	@warning_ignore("narrowing_conversion")
	var pos_key = Vector2i(spawn_pos.x, spawn_pos.z)
	if occupied_pos.has(pos_key): return
	occupied_pos[pos_key] = true
	var new_stone = nature_res.instantiate()
	new_stone.res_type = NatureRes.ResType.STONE
	new_stone.drop_count = randi_range(2, 9) if drop_count == 0 else drop_count
	new_stone.position = spawn_pos
	new_stone.position.y -= 0.25
	add_child(new_stone)
	stones.append(new_stone)

func _spawn_grass(spawn_pos: Vector3):
	@warning_ignore("narrowing_conversion")
	var pos_key = Vector2i(spawn_pos.x, spawn_pos.z)
	if occupied_pos.has(pos_key): return
	occupied_pos[pos_key] = true
	var new_grass = nature_res.instantiate()
	new_grass.res_type = NatureRes.ResType.GRASS
	new_grass.drop_count = 1
	new_grass.position = spawn_pos
	new_grass.position.y -= 0.1
	add_child(new_grass)
	grasses.append(new_grass)

#func place_object(glob_pos: Vector3, obj_type: GManager.ObjType):
	#var new_obj = GManager.objects[obj_type].instantiate()
	#add_child(new_obj)
	#new_obj.global_position = glob_pos
	#o_objs.append(new_obj)
