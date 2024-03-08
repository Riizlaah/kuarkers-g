extends RigidBody3D

const ex_area = preload("res://scene/ex_area.tscn")

var throw_force = 20.0
var ex_range = 1.5
var damage = 50
#var effect
var mesh: PackedScene
@onready var timer = $Timer

func _ready():
	add_child(mesh.instantiate())

func throw(dir, countdown):
	apply_impulse(dir * throw_force)
	timer.wait_time = countdown
	timer.start()

func _on_countdown_timeout():
	var explod = ex_area.instantiate()
	explod.radius = ex_range
	explod.damage = damage
	explod.position = global_position
	get_node("/root/WorldLoader").add_child(explod)
	queue_free()
