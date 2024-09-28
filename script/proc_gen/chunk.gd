class_name TerrainChunk
extends MeshInstance3D

const nature_res = preload("res://scene/proc_gen/nature_res.tscn")
const ctr_offset = 0.5
const erosion = {}
var resolution := Settings.lods[2]
var adj_terrain_h := 20
var chunk_size := Settings.CHUNK_SIZE
const lods := Settings.lods
const lods_dist := Settings.lods_dist
var coord = Vector2()
var set_colls := true
var is_flat: bool
var tile_size := 0.0
#var vertexes = []
var occupied_pos := {}
var texture_created := false
var tiles := {}
var lfd := false
var biomes: Array[Biome]
var should_remove := false

#Noises
var cont_noise: FastNoiseLite
var erosion_noise: FastNoiseLite
var pv_noise: FastNoiseLite
var humid_noise: FastNoiseLite
var temp_noise: FastNoiseLite
#Spline Points
var cont_sps: Curve
var erosion_sps: Curve
var pv_sps: Curve

#objects in chunk
var trees = []
var grasses = []
var stones = []
var o_objs = []
func _init():
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WEB_GREEN
	material_overlay = mat

func _ready():
	var parent: TerrainGenerator = get_parent()
	cont_noise = parent.cont_noise
	erosion_noise = parent.erosion_noise
	pv_noise = parent.pv_noise
	humid_noise = parent.humid_noise
	temp_noise = parent.temp_noise
	cont_sps = parent.cont_sps
	erosion_sps = parent.erosion_sps
	pv_sps = parent.pv_sps
	biomes = get_parent().biomes
	set_process(false)
	set_physics_process(false)
	#var new_node = MeshInstance3D.new()
	#var new_node_mesh = BoxMesh.new()
	#new_node_mesh.size.y = 40
	#new_node.mesh = new_node_mesh
	#add_child(new_node)
	#RenderingServer.set_debug_generate_wireframes(true)
	#RenderingServer.viewport_set_debug_draw(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_DEBUG_DRAW_WIREFRAME)

func gen_mesh(pos: Vector2, size: int, init_visible: bool, load_fd: bool, is_flat2: bool, res := Settings.lods[2]):
	chunk_size = size
	coord = pos * size
	resolution = res
	lfd = load_fd
	is_flat = is_flat2
	@warning_ignore("integer_division")
	tile_size = chunk_size / res
	#var idx_count = 0
	var surf_tool = SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surf_tool.index()
	for z in resolution:
		for x in resolution:
			var tile_pos = Vector3(x * tile_size, 0, z * tile_size)
			var global_pos = Vector2(tile_pos.x + coord.x, tile_pos.z + coord.y)
			var noises := get_biome_height_blended(global_pos)
			if !is_flat:
				#tile_pos.y = noises[0]
				tile_pos.y = snappedf(noises[0], 1)
			var quad := [
				Vector3(tile_pos.x + -tile_size/2, tile_pos.y, tile_pos.z + tile_size/2),
				Vector3(tile_pos.x + tile_size/2, tile_pos.y, tile_pos.z + tile_size/2),
				Vector3(tile_pos.x + tile_size/2, tile_pos.y, tile_pos.z + -tile_size/2),
				Vector3(tile_pos.x + -tile_size/2, tile_pos.y, tile_pos.z + -tile_size/2)
			]
			create_tile(tile_pos, Vector3(global_pos.x, tile_pos.y, global_pos.y), quad, noises)
			#var quad_verts = [
				#tile_pos - Vector3(tile_size*0.5, 0, tile_size*0.5),
				#tile_pos + Vector3(tile_size*0.5, 0, -tile_size*0.5),
				#tile_pos + Vector3(tile_size*0.5, 0, tile_size*0.5),
				#tile_pos - Vector3(0, 0, tile_size*0.5)
			#]
			#surf_tool.add_vertex(quad_verts[0])
			#surf_tool.add_vertex(quad_verts[1])
			#surf_tool.add_vertex(quad_verts[2])
			#surf_tool.add_vertex(quad_verts[3])
			#
			#surf_tool.add_index(idx_count)
			#surf_tool.add_index(idx_count + 1)
			#surf_tool.add_index(idx_count + 2)
			#surf_tool.add_index(idx_count)
			#surf_tool.add_index(idx_count + 2)
			#surf_tool.add_index(idx_count + 3)
			#idx_count += 4
			#var percent = Vector2(x, z) / resolution
			#var point_on_mesh = Vector3((percent.x - ctr_offset), 0, (percent.y - ctr_offset))
			#var vertex = point_on_mesh * size
			#var global_pos = Vector2(coord.x + vertex.x, coord.y + vertex.z)
			#var noises_val: Array[float]
			#if is_nan(global_pos.x) or is_nan(global_pos.y): continue
			##var biome = identify_biome(global_pos)
			#if !is_flat:
				#noises_val = get_biome_height_blended(global_pos)
				#vertex.y = noises_val[0]
				#vertex.y = snappedf(vertex.y, 1)
			#if is_nan(vertex.y): continue
			#surf_tool.set_uv(percent)
			##surf_tool.add_vertex(vertex)
			##if !vertexes.has(vertex): vertexes.append(vertex)
			#create_tile(vertex, noises_val)
	#for tile in tiles:
		#surf_tool.add_vertex(tile.pos)
		#surf_tool
		#GManager.vertex_count += 1
	surf_tool.optimize_indices_for_cache()
	surf_tool.generate_normals()
	mesh = surf_tool.commit()
	if set_colls: create_colls()
	set_chunk_visible(init_visible)
	#tiles_identify_biomes()

func pack_and_remove() -> ChunkDat:
	var cdat = ChunkDat.new(resolution, chunk_size, tiles, global_position, is_flat)
	return cdat

func commit_mesh(surf_tool: SurfaceTool):
	#surf_tool.index()
	#var vert = 0
	#for z in resolution:
		#for x in resolution:
			#surf_tool.add_index(vert)
			#surf_tool.add_index(vert + 1)
			#surf_tool.add_index(vert + resolution + 1)
			#surf_tool.add_index(vert + resolution + 1)
			#surf_tool.add_index(vert + 1)
			#surf_tool.add_index(vert + resolution + 2)
			#vert += 1
		#vert += 1
	#surf_tool.optimize_indices_for_cache()
	#if !is_flat: surf_tool.generate_normals()
	#if !lfd: place_objects()
	#surf_tool.index()
	return surf_tool.commit()

func create_texture():
	var img = Image.create(resolution, resolution, true, Image.FORMAT_RGB8)
	for tile in tiles:
		var vect = vert_to_pix(tile.pos)
		if vect.y >= resolution or vect.x >= resolution: continue
		img.set_pixelv(vect, tile.biome.color)
	var mat = StandardMaterial3D.new()
	var texr = ImageTexture.create_from_image(img)
	mat.albedo_texture = texr
	material_override = mat

func vert_to_pix(vert: Vector3) -> Vector2:
	@warning_ignore("integer_division")
	var offset := chunk_size / 2
	@warning_ignore("integer_division")
	var resl := resolution / 8
	var p_x := (vert.x + offset) / resl
	var p_y := (vert.z + offset) / resl
	#print(vert)
	return Vector2(p_x, p_y)

func get_biome_height_blended(pos: Vector2) -> Array[float]:
	#var height := 0.0
	var cont_val := (cont_noise.get_noise_2dv(pos) + 1) / 2
	var erosion_val := (erosion_noise.get_noise_2dv(pos) + 1) / 2
	var pv_val := (pv_noise.get_noise_2dv(pos) + 1) / 2
	var arr: Array[float] = [0.0, cont_val, erosion_val, pv_val]
	arr[0] += cont_sps.sample(cont_val)
	if cont_val < 0.7: return arr
	arr[0] += erosion_sps.sample(erosion_val)
	if erosion_val < 0.25: return arr
	arr[0] += pv_sps.sample(pv_val) * 0.75
	return arr

func tiles_identify_biomes():
	var parent: TerrainGenerator = get_parent()
	for tile in tiles:
		var tile_pos2 = Vector2(tile.pos.x + coord.x, tile.pos.y + coord.y)
		if parent.biome_map.has(tile_pos2):
			tile.biome = parent.biome_map[tile_pos2]
			continue
		tile.biome = await parent.get_biome(tile_pos2)
		parent.biome_map[tile_pos2] = tile.biome
	create_texture()

func create_tile(pos: Vector3, global_pos: Vector3, quad: Array[Vector3], noises_val: Array[float]):
	var tile = Tile3D.new(pos, global_pos, quad, noises_val)
	tiles[pos] = tile
	#if !tile.biome.is_reached_percentage(): return
	#var obj = tile.mk_object()
	#add_child(obj)
	#obj.position = tile.pos

#func place_objects_in_tile(tile: Tile3D):
	#var percentage = randi() % 1000 + 1
	#match tile.biome.name:
		#'rocky': if percentage < 10: _spawn_stone(tile.pos)
		#'grassland': if percentage < 70: _spawn_grass(tile.pos)
		#'forest': if percentage < 20: _spawn_tree(tile.pos)
		#'mountains': if percentage < 10: _spawn_stone(tile.pos)
		#'hills': if percentage < 5: _spawn_tree(tile.pos)
		#'high_mountains': if percentage < 5: _spawn_stone(tile.pos)

func load_datas(trees2, grasses2, stones2):
	for tree in trees2: _spawn_tree(tree.pos, tree.height)
	for grass in grasses2: _spawn_grass(grass.pos)
	for stone in stones2: _spawn_stone(stone.pos, stone.drop_count)

func update_lod(res: int):
	gen_mesh(coord / chunk_size, chunk_size, true, false, get_parent().is_flat, res)
	#var viewer_dist = coord.distance_to(view_pos)
	#var update = false
	#var new_lod = lods[0]
	#for i in lods.size():
		#if viewer_dist < lods_dist[i]: new_lod = lods[i]
	#if new_lod >= lods[lods.size() - 1]: set_colls = true
	#else: set_colls = false
	#if resolution != new_lod:
		#resolution = new_lod
		#update = true
	#return update

func get_quad_inpos(g_pos: Vector2):
	var c_coord = Vector2i(floor(g_pos.x / (chunk_size * tile_size)), floor(g_pos.y / (chunk_size * tile_size)))
	var t_pos = Vector2i(floor(g_pos.x / tile_size) % chunk_size, floor(g_pos.y / tile_size) % chunk_size)
	var parent: TerrainGenerator = get_parent()
	return parent.chunks[c_coord].tiles[t_pos].quad

func update_chunk(view_pos: Vector2, max_dist):
	var viewer_dist = coord.distance_to(view_pos)
	var is_visib = viewer_dist <= (max_dist * 1.5)
	set_chunk_visible(is_visib)
	#var lod: int = lods[0]
	#for i in lods.size():
		#if viewer_dist < lods_dist[i]: lod = lods[i]
	#if lod >= lods[-1]: set_colls = true
	#else: set_colls = false
	#if resolution != lod:
		#update_lod(lod)

func create_colls():
	if has_node("StaticBody3D"): get_node("StaticBody3D").queue_free()
	create_trimesh_collision()

func set_chunk_visible(visib: bool):
	var colls = get_node_or_null("StaticBody3D")
	if visib == true:
		show()
		should_remove = false
		if is_instance_valid(colls): colls.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		hide()
		should_remove = true
		if is_instance_valid(colls): colls.process_mode = Node.PROCESS_MODE_DISABLED
		#var parent: TerrainGenerator = get_parent()
		#var vcc = coord / chunk_size
		#parent.chunks.erase(vcc)
		#parent.packed_chunk[vcc] = ChunkDat.new(resolution, chunk_size, tiles, global_position, is_flat)
		#queue_free()

#func reduce_slope(height: float, slope_factor: float) -> float:
	#return height * (1.0 - slope_factor) + slope_factor * smoothstep(0.0, 1.0, height)

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
	var pos_key = Vector2(spawn_pos.x, spawn_pos.z)
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
	var pos_key = Vector2(spawn_pos.x, spawn_pos.z)
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
