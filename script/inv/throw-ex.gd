extends RigidBody3D
class_name Grenade

const throw_f = 10
const exarea = preload("res://scene/ExArea.tscn")
var wait_time = 180
@onready var rtw_node = get_tree().get_root().get_node("/root/World")

func throw(dir):
	apply_impulse(dir * throw_f)
func _physics_process(_delta):
	wait_time -= 1
	if wait_time == 0:
		explode()
func explode():
	var ex_area = exarea.instantiate()
	ex_area.position = global_position
	rtw_node.add_child(ex_area)
	ex_area.explode()
	queue_free()
	
