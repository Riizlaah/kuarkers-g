extends Area3D
class_name ExArea

@onready var anim = $AnimationPlayer

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
		body.takeDamage(50)
	queue_free()

