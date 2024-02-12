extends ItemType
class_name MeleeType

@export_range(5,50) var damage_i: int: set = set_dmg

func set_dmg(val):
	damage_i = val
	damage = damage_i
