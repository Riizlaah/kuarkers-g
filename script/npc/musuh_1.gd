class_name Musuh1
extends CharacterBody3D

@onready var area = $Area3D

var time = 16
var target
var hp = 80

func _on_area_3d_body_entered(body: Node3D):
	if body is Musuh1: return
	target = body

func _physics_process(delta):
	if target != null:
		var direction = position.direction_to(target.position)
		look_at(target.position)
		velocity = direction * 10
	if !is_on_floor():
		velocity.y -= 15 * delta
	if velocity == Vector3.ZERO:
		rotate_y(5 * delta)
	move_and_slide()

func _on_area_3d_body_exited(_body):
	target = null
	velocity = Vector3.ZERO
	rotation.x = 0
	rotation.z = 0

func tabrak(_body):
	target.launch(-global_transform.basis.z + (global_transform.basis * Vector3(-1,0.25,-1)))

func takeDamage(dmg):
	hp -= dmg
	if hp < 0:
		queue_free()
