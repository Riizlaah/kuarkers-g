extends CharacterBody3D

const speed = 20
const exarea = preload("res://scene/ExArea.tscn")
var tmp_velo: Vector3
@onready var world_node = get_tree().get_root().get_node("/root/World")

func launch(dir):
	look_at(dir * 5)
	tmp_velo = dir * speed

func _physics_process(_delta):
	velocity = tmp_velo * 2.5
	move_and_slide()

func on_area3d_body_entered(_body):
	var ex_area = exarea.instantiate()
	ex_area.position = global_position
	world_node.add_child(ex_area)
	ex_area.explode()
	queue_free()


