extends Object
class_name Tile3D

var glob_pos: Vector3
var biome: Biome
var pos: Vector3
#var uv: Vector2
var objects: Node3D
var nars_drop_count := 0#nars = NatureRes
var nars_destr_phase := -1
#var cont_val: float
#var erosion_val: float
#var pv_val: float
var quad: Array[Vector3]

func _init(tile_pos: Vector3, g_pos: Vector3, quad: Array[Vector3], noises_val: Array[float]):
	pos = tile_pos
	glob_pos = g_pos
	#cont_val = noises_val[1]
	#erosion_val = noises_val[2]
	#pv_val = noises_val[3]
	quad = quad
	#uv = uv2
	#biome = tile_biome

func mk_object() -> NatureRes:
	return biome.mk_object(nars_drop_count, nars_destr_phase)

func add_nature_res(obj):
	objects = obj
