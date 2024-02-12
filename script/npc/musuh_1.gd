class_name Musuh1
extends CharacterBody3D

@onready var area = $Area3D
@onready var label_3d = $Label3D

var time = 16
var target
var hp = 80

func _enter_tree():
	set_multiplayer_authority(1)

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

func tabrak(body):
	body.launch(body.name, -global_transform.basis.z + (global_transform.basis * Vector3(0,0.1,-1)))
	target = null

func takeDamage(dmg):
	hp -= dmg
	label_3d.text = str(hp)
	if hp < 0:
		delete.rpc()
@rpc("call_local")
func delete():
	queue_free()
