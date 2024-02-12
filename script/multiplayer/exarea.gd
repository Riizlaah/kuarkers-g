extends Area3D
class_name ExArea

@onready var anim = $AnimationPlayer
var explode_damage := 50

func _enter_tree():
	set_multiplayer_authority(1)

func _ready():
	set_physics_process(false)

func explode():
	anim.play("explode")
	await get_tree().create_timer(0.25).timeout
	var bodies = get_overlapping_bodies()
	if bodies.is_empty() == true:
		queue_free()
		return
	for body in bodies:
		if body is Musuh1:
			body.takeDamage(explode_damage, true)
			break
		var dir = global_position.direction_to(body.global_position) * 2
		body.takeDamage(explode_damage, true)
		body.launch.rpc(body.name, dir, 10)
	queue_free()

