extends Area3D
class_name ExArea

@onready var anim = $AnimationPlayer

func _ready():
	set_physics_process(false)

func explode():
	var bodies = get_overlapping_bodies()
	await anim.play("explode")
	if bodies.is_empty() == true:
		return
	for body in bodies:
		if body.has_method("takeDamage"):
			body.takeDamage(50)
	queue_free()

