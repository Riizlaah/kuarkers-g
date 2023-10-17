extends CharacterBody3D

#const
const SPEED = 5
const ATTACK_RANGE = 3
const CHASE_RANGE = 9
const look_r = 10
const STOPPING_DISTANCE = 2
const w_range = 20.0
const MAX_HP = 100


#Node
@onready var player = $"../Char"
@onready var anim = $Animasi
@onready var rayc = $Head/RayCast3D


#var
var a_p
var n_pos = Vector3.ZERO
var state = 0
var current_hp = MAX_HP
var has_free : bool = false
var r_pos
var c_pos
var c_targ = null

func _ready():
	#r_pos = [Vector3(position.x - w_range, 0, position.z - w_range), Vector3(position.x + w_range, 0, position.z + w_range)]
	c_pos = position


func _physics_process(delta):
	if has_free == true:
		return
	if !is_on_floor():
		velocity.y -= 10 * delta
	var distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)
	if current_hp == 0:
		die()
		#current_hp = -1
		return
	if distance_to_player < look_r:
		rotate_to_player()
	if distance_to_player < ATTACK_RANGE:
		attack_player()
		state = 1
	elif distance_to_player < CHASE_RANGE:
		chase_player(player.global_transform.origin)
		state = 0
	else:
		state = 0
		move_randomly()
	play_anim()

func play_anim():
	if state == 1:
		#anim.play("RESET")
		anim.play("punch")
	else:
		anim.play("move")
	pass

func c_n_pos():
	n_pos = Vector3(rand_range(-w_range, w_range), 0, rand_range(-w_range, w_range)) + c_pos
	pass

func move_randomly():
	if (n_pos.x - position.x <= 0 and n_pos.z - position.z <= 0):
		n_pos = Vector3.ZERO
	if n_pos == Vector3.ZERO:
		c_n_pos()
	else:
		pass
	n_pos.y = 2
	look_at(n_pos)
	rotation.x = 0
	rotation.z = 0
	var move = n_pos.normalized()
	var dir = (transform.basis * move).normalized()
	if dir:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()

func chase_player(target_position):
	var direction = (target_position - global_transform.origin).normalized()
	velocity = direction * SPEED
	move_and_slide()
	pass

func rotate_to_player():
	look_at(player.position)
	rotation.z = 0
	rotation.x = 0
	pass

func attack_player():
	if rayc.is_colliding():
		a_p = rayc.get_collider()
		a_p.take_damage(2)
	pass
	
func reduce_hp(amount):
	current_hp -= amount
	current_hp = clamp(MAX_HP, 0, MAX_HP)

func die():
	position.y = -50
	queue_free()
	has_free = true
	#visible = false  # Hapus NPC dari permainan ketika mati

func rand_range(minm: float, maxm: float):
	return ceil(randf_range(minm, maxm))


func _on_entered(body):
	if body is CharacterBody3D:
		var distance = (body.global_transform.origin - global_transform.origin).length_squared()
		if c_targ == null or distance < (c_targ.global_transform.origin - global_transform.origin).length_squared():
			c_targ = body
	pass # Replace with function body.

func _on_exited(body):
	if body == c_targ:
		c_targ = null
	pass # Replace with function body.

func get_c_targ():
	return c_targ

func player_interact():
	current_hp -= 20





