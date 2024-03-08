extends Area3D
class_name Portal

@export var dest: Portal
@export var portal_title := "Portal"

func _ready():
	$Label3D.text = portal_title
	$Label3D2.text = portal_title

func _on_portal_entered(body: Node3D):
	var glob_pos = (dest.global_position + -body.global_basis.z) + (body.global_basis * Vector3(0, 0, -2))
	body.global_position = glob_pos
