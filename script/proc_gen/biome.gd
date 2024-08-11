class_name Biome
extends Resource

@export var name := ""
@export var height := 0.0
@export var adjustment_height := 0.0
@export var color := Color.GREEN
@export var is_height_abs := false

func calc_hieght(height2: float) -> float:
	if is_height_abs:
		return abs(height2) * adjustment_height
	return height2 * adjustment_height

#func get_height() -> float:
	#return adjustment_height

