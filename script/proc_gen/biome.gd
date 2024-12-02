class_name Biome
extends Resource

@export var name := ""
@export var min_height := 0.0
@export var max_height := 1.0
@export var color := Color.GREEN

func is_req_valid(h: float) -> bool:
	return between(h, min_height, max_height)

func between(n: float, minv: float, maxv: float) -> bool:
	return n <= maxv and n >= minv
