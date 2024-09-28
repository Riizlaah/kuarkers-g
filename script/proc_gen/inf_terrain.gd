class_name TerrainGenerator
extends WorldTemplate

const CHUNK_SIZE := Settings.CHUNK_SIZE
@export var terrain_height := 20
@export var biomes: Array[Biome]
@export_group("Noises")
@export var cont_noise: FastNoiseLite
@export var erosion_noise: FastNoiseLite
@export var pv_noise: FastNoiseLite
@export var temp_noise: FastNoiseLite
@export var humid_noise: FastNoiseLite
@export_group("Spline Points")
@export var cont_sps: Curve
@export var erosion_sps: Curve
@export var pv_sps: Curve
var viewer: Node3D
var view_dist: int
var noises: Array[FastNoiseLite]
var viewer_pos := Vector2.ZERO
var last_viewer_pos := Vector2(1, 1)
var chunks = {}
var chunk_visible := 0
var last_visible_chunks := []
var lfd := true
var is_flat := false
var visible_chunks_count: Array
var chunk_initiated := false
var packed_chunk := {}
var biome_map := {}
#@onready var biomes_res: ResourcePreloader = $Biomes

func _ready():
	#for res_name in biomes_res.get_resource_list():
		#biomes[res_name] = biomes_res.get_resource(res_name)
	chunk_visible = Settings.render_distance + 2
	view_dist = chunk_visible * CHUNK_SIZE
	var world_seed = GManager.world_data.seed
	temp_noise.seed = world_seed + 8
	humid_noise.seed = world_seed - 8
	cont_noise.seed = world_seed
	erosion_noise.seed = world_seed
	pv_noise.seed = world_seed
	noises = [cont_noise, erosion_noise, pv_noise, temp_noise, humid_noise]
	var dist_range = view_dist * 4
	await bake_biome_map(Vector2(-dist_range, -dist_range), Vector2(dist_range, dist_range))
	check_world_method()
	set_physics_process(false)

func players_added():
	viewer = get_parent().players.get_node(str(multiplayer.get_unique_id()))

func check_world_method():
	viewer = $start_pos
	if GManager.world_data.type == 1: is_flat = true
	if !GManager.new_world:
		lfd = true
		load_data()
		return
	lfd = false
	update_visible_chunk()
	$Timer.start()

func load_data():
	var c_datas = GManager.world_data.extra_data
	if c_datas.is_empty():
		get_tree().quit()
		return
	for chunk in c_datas:
		var new_chunk := TerrainChunk.new()
		var vcc: Vector2 = chunk.chunk_coord / CHUNK_SIZE
		new_chunk.adj_terrain_h = terrain_height
		add_child(new_chunk)
		new_chunk.global_position = chunk.pos
		new_chunk.gen_mesh(vcc, CHUNK_SIZE, false, true, is_flat)
		chunks[vcc] = new_chunk
		new_chunk.load_datas(chunk.trees, chunk.grasses, chunk.stones)
	update_visible_chunk()
	$Timer.start()

func update_visible_chunk():
	var curr_x := roundi(viewer_pos.x / CHUNK_SIZE)
	var curr_y := roundi(viewer_pos.y / CHUNK_SIZE)
	visible_chunks_count = range(-chunk_visible, chunk_visible)
	for y_offset in visible_chunks_count:
		for x_offset in visible_chunks_count:
			#vcc = View Chunk Coord
			var vcc := Vector2(curr_x - x_offset, curr_y - y_offset)
			if chunks.has(vcc):
				await chunks[vcc].update_chunk(viewer_pos, view_dist)
				if chunks[vcc].should_remove == true:
					packed_chunk[vcc] = chunks[vcc].pack_and_remove()
					chunks[vcc].queue_free()
					chunks.erase(vcc)
				continue
			if packed_chunk.has(vcc):
				chunks[vcc] = packed_chunk[vcc].create_chunk(self)
				continue
			var chunk := TerrainChunk.new()
			var pos := vcc * CHUNK_SIZE
			add_child(chunk)
			chunk.global_position = Vector3(pos.x, 0, pos.y)
			chunk.gen_mesh(vcc, CHUNK_SIZE, false, false, is_flat)
			chunks[vcc] = chunk
			#if chunks.has(view_chunk_coord):
				#chunks[view_chunk_coord].update_chunk(viewer_pos, view_dist)
				#if chunks[view_chunk_coord].update_lod(viewer_pos):
					#chunks[view_chunk_coord].gen_mesh(view_chunk_coord, CHUNK_SIZE, true, lfd, is_flat)
				#if chunks[view_chunk_coord].visible: last_visible_chunks.append(chunks[view_chunk_coord])
			#else:
				#var chunk := TerrainChunk.new()
				#var pos := view_chunk_coord * CHUNK_SIZE
				#var world_pos := Vector3(pos.x, 0, pos.y)
				#add_child(chunk)
				#chunk.global_position = world_pos
				#chunk.gen_mesh(view_chunk_coord, CHUNK_SIZE, false, false, is_flat)
				#chunks[view_chunk_coord] = chunk
	if chunks.size() >= visible_chunks_count.size() and !chunk_initiated:
		chunk_initiated = true
		await set_world_spawn()
		get_parent().world_loaded()

func save_world():
	var saved_chunks = []
	for chunk in chunks.values():
		var chunk_dat = chunk.get_saves()
		saved_chunks.append({
			'pos': chunk.global_position,
			'trees': chunk_dat[0],
			'grasses': chunk_dat[2],
			'stones': chunk_dat[1],
			'chunk_coord': chunk_dat[4]
		})
	return saved_chunks

func process():
	viewer_pos.x = viewer.position.x
	viewer_pos.y = viewer.position.z
	if !viewer_pos.is_equal_approx(last_viewer_pos):
		update_visible_chunk()
		last_viewer_pos = viewer_pos


func bake_biome_map(min_pos: Vector2, max_pos: Vector2) -> bool:
	for x in range(min_pos.x, max_pos.x):
		for y in range(min_pos.y, max_pos.y):
			var pos = Vector2(x, y)
			biome_map[pos] = get_biome(pos)
	return true

func get_biome(pos: Vector2):
	var cont_val = cont_noise.get_noise_2dv(pos)
	#var erosion_val = erosion_noise.get_noise_2dv(pos)
	var temp = temp_noise.get_noise_2dv(pos)
	var humid = humid_noise.get_noise_2dv(pos)
	for biome in biomes:
		if !biome.is_req_valid(cont_val, temp, humid): continue
		return biome
	return biomes[4]# grassland

#func get_biome(pos: Vector2):
	#var cont_val = cont_noise.get_noise_2dv(pos)
	#var erosion_val = erosion_noise.get_noise_2dv(pos)
	#if cont_val < -0.78:
		#return calc_erosion(erosion_val, pos)
	#elif cont_val < -0.375:
		#return calc_erosion(erosion_val, pos)
	#elif cont_val < -0.2225:
		#return calc_erosion(erosion_val, pos)
	#else:
		#return calc_erosion(erosion_val, pos)
#
#func calc_erosion(erosion_val: float, pos: Vector2):
	#if erosion_val < -0.78:
		#pass
	#elif erosion_val < -0.375:
		#pass
	#elif erosion_val < -0.2225:
		#pass
	#elif erosion_val < 0.05:
		#pass
	#elif erosion_val < 0.45:
		#pass
	#elif erosion_val < 0.55:
		#pass
	#else:
		#pass
#
#func calc_temphumid(pos: Vector2):
	#var temp = temp_noise.get_noise_2dv(pos)
	#var humid = humid_noise.get_noise_2dv(pos)
	#
