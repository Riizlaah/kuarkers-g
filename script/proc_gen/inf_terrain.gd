class_name TerrainGenerator
extends WorldTemplate

const CHUNK_SIZE := Settings.CHUNK_SIZE
@export var terrain_height := 20
@export var tree_scene: PackedScene
@export var stone_scenes: Array[PackedScene]
@export var color_test: Color
@export var biomes: Array[Biome]
@export_group("Noises")
@export var small_noise: FastNoiseLite
@export var large_noise: FastNoiseLite
@export var height_noise: FastNoiseLite
@export var temp_noise: FastNoiseLite
@export var humid_noise: FastNoiseLite
@export_group("Curves")
@export var small_curve: Curve
@export var large_curve: Curve
@export var height_curve: Curve
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

func _ready():
	chunk_visible = Settings.render_distance
	view_dist = chunk_visible * CHUNK_SIZE
	var world_seed : int = GManager.world_data.seed
	large_noise.seed = world_seed
	small_noise.seed = world_seed + 1
	height_noise.seed = world_seed - 1
	noises = [large_noise, small_noise, height_noise]
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
	for chunk in last_visible_chunks:
		chunk.set_chunk_visible(false)
	last_visible_chunks.clear()
	var curr_x := roundi(viewer_pos.x / CHUNK_SIZE)
	var curr_y := roundi(viewer_pos.y / CHUNK_SIZE)
	visible_chunks_count = range(-chunk_visible, chunk_visible)
	for y_offset in visible_chunks_count:
		for x_offset in visible_chunks_count:
			var view_chunk_coord := Vector2(curr_x - x_offset, curr_y - y_offset)
			if chunks.has(view_chunk_coord):
				chunks[view_chunk_coord].update_chunk(viewer_pos, view_dist)
				#if chunks[view_chunk_coord].update_lod(viewer_pos):
					#chunks[view_chunk_coord].gen_mesh(view_chunk_coord, CHUNK_SIZE, true, lfd, is_flat)
				if chunks[view_chunk_coord].visible: last_visible_chunks.append(chunks[view_chunk_coord])
			else:
				var chunk := TerrainChunk.new()
				var pos := view_chunk_coord * CHUNK_SIZE
				var world_pos := Vector3(pos.x, 0, pos.y)
				add_child(chunk)
				chunk.global_position = world_pos
				chunk.gen_mesh(view_chunk_coord, CHUNK_SIZE, false, false, is_flat)
				chunks[view_chunk_coord] = chunk
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
	#if !last_viewer_pos.is_equal_approx(viewer_pos):
	viewer_pos.x = viewer.position.x
	viewer_pos.y = viewer.position.z
	update_visible_chunk()
