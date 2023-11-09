extends CharacterBody3D
class_name Bullet3D

const bullet_v = 99
var damage_bullet = 5
var d_time = 180
var tmp_velocity : Vector3

func _physics_process(_delta):
	velocity = tmp_velocity
	move_and_slide()
	d_time -= 1
	if d_time == 0:
		queue_free()
	pass

func throw(dir: Vector3):
	tmp_velocity = dir * bullet_v
	#move_and_slide()
	pass

func _on_body_entered(body: Node3D):
	#if body.has_method("takeDamage"):
	body.takeDamage(damage_bullet)
	queue_free()
	pass # Replace with function body.
