extends ItemType
class_name MeleeType

#const throw = preload("res://scene/inv/Throwable.tscn")

@export var throwable: bool = false
@export_range(5,99) var damage_i: int = 5

#func r_click(arr):
#	if Throwable_i == true:
#		var throw_i = throw.instantiate()
#		throw_i.position = -arr[0].global_transform.basis.z + arr[0].global_position + Vector3(0,0,-1)
#		throw_i.set_item(arr[1])
#		throw_i.apply_force((-arr[0].global_transform.basis.z + arr[0].global_position + Vector3(0,0,-1)) * 5)
#	pass
