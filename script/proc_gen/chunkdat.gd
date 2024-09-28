extends Object
class_name ChunkDat

var res: int
var size: int
var tiles: Dictionary
var pos: Vector3
var is_flat: bool
#var blocks

func _init(res2: int, size2: int, tiles2: Dictionary, pos2: Vector3, is_flat2: bool) -> void:
	res = res2
	size = size2
	tiles = tiles2
	pos = pos2
	is_flat = is_flat2

func create_chunk(parent: TerrainGenerator):
	var chunk = TerrainChunk.new()
	parent.add_child(chunk)
	chunk.gen_mesh(Vector2(pos.x / size, pos.z / size), size, false, true, is_flat, res)
	return chunk
