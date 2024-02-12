extends CharacterBody3D

const time = 60
var gravity = 30
var q_time
var curr_index = 0
@onready var mesh = $Mesh
@onready var lb_msg = $Label3D

var texts = ["Halo !", ":v", "Yes", "No", ":)", "Apa Kau lihat-lihat?", ":(", "Very gudd", "Semoga harimu menyenangkan", "Maaf", " Syukron", "Thanks"]

var target: Vector3
func _ready():
	_set_new_target_pos()
	q_time = time

func _physics_process(delta):
	for ray in $Detector.get_children():
		if !ray.is_colliding:
			_set_new_target_pos()
			return
	if global_position.distance_to(target) < 10:
		_set_new_target_pos()
		return
	velocity = to_local(target) * 0.8
	if !is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	velocity = velocity
	if velocity.length() < 5:
		q_time -= 1
		if q_time == 0:
			_set_new_target_pos()
			q_time = time

func _set_new_target_pos():
	set_physics_process(false)
	await get_tree().create_timer(2.5).timeout
	target = Vector3(randf_range(-30, 30), randf_range(1, 5), randf_range(-30, 30))
	target.x += position.x
	target.z += position.z
	set_physics_process(true)

func _on_timer_timeout():
	mesh.material_override.set("albedo_color", Color(randf_range(0, 1), randf_range(0, 1), randf_range(0, 1)))

func _on_timer2_timeout():
	lb_msg.text = texts.pick_random()
