extends CharacterBody3D

const speed = 3000
const ex_area = preload("res://scene/ex_area.tscn")
var ex_radius = 6.5
var ex_damage = 180
var tmp_velo

func launch(dir):
	look_at(position + dir)
	tmp_velo = dir * speed

func _physics_process(delta):
	velocity = tmp_velo * delta
	move_and_slide()

func _on_contact(_body):
	var exar = ex_area.instantiate()
	exar.position = global_position
	exar.damage = ex_damage
	exar.radius = ex_radius
	get_node("/root/WorldLoader").add_child(exar)
	queue_free()
