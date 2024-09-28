extends Resource
class_name Biome

const nature_scene = preload("res://scene/proc_gen/nature_res.tscn")

@export var name := ""
@export var elevation_min := -1.25
@export var elevation_max := 1.25
@export var heatmap_min := -1.0
@export var heatmap_max := 1.0
@export var moisture_min := -1.0
@export var moisture_max := 1.0
@export var adjustment_height := 1.0
@export var color := Color.GREEN
@export var nature_type := NatureRes.ResType.TREE
@export var nars_min_percentage := 0
#@export var is_height_abs := false

func is_req_valid(elevation: float, heatmap: float, moisture: float) -> bool:
	if !between(elevation, elevation_min, elevation_max): return false
	if !between(heatmap, heatmap_min, heatmap_max): return false
	if !between(moisture, moisture_min, moisture_max): return false
	return true

func between(val: float, minimal: float, maximal: float) -> bool: return val > minimal and val < maximal

func mk_object(drop_count := 0, destr_phase := -1) -> NatureRes:
	var scn = nature_scene.instantiate()
	scn.res_type = nature_type
	scn.drop_count = drop_count
	scn.destr_phase = destr_phase
	return scn

func is_reached_percentage() -> bool: return randi_range(0, 1000) < nars_min_percentage
