extends CharacterBody3D

const SPEED = 10
const gravity = 10
const wanderingArea = 15
const minDistance = 1.0

var wanderingPos
var target
var wanderingDirection
var moveTimer = 2.0
var c_pos

func _ready():
	c_pos = position
	c_pos.y = 0
	ch_new_pos()

func _physics_process(delta):
	if !is_on_floor():
		velocity.y -= gravity * delta
		move_and_slide()
	if target == null:
		if ceil(position.x) == wanderingPos.x or wanderingPos.z == ceil(position.z):
			await get_tree().create_timer(3).timeout
			ch_new_pos()
		else:
			wandering()
	pass

func wandering():
	look_at(wanderingPos)
	rotation.x = 0
	rotation.z = 0
	var dir = (transform.basis * wanderingDirection).normalized()
	if dir:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	print(wanderingPos,position)
	move_and_slide()

func ch_new_pos():
	var x_coor = ceil(randf_range(-wanderingArea, wanderingArea) + c_pos.x)
	var z_coor = ceil(randf_range(-wanderingArea, wanderingArea) + c_pos.z)
	wanderingPos = Vector3i(x_coor, 2, z_coor)
	wanderingDirection = position.direction_to(wanderingPos)

func _on_timer_timeout():
	pass
func on_body_entered():
	pass
