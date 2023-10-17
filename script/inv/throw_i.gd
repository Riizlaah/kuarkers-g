extends RigidBody3D
class_name ThrowItem

var throwForce = 50.0
var item_data: itemData
@onready var sprite = $Sprite3D

func throw(direction, item_d: itemData):
	sprite.texture = item_d.icon
	item_data = item_d
	apply_impulse(direction * throwForce)
#	var camera = $Camera Ganti ini dengan referensi kamera Anda.
#	var camera_transform = camera.global_transform
#	var direction = -camera_transform.basis.z  # Arah lemparan adalah ke arah depan kamera.


func _on_body_entered(body: Node3D):
	if body.has_method("takeDamage"):
		body.takeDamage(item_data.type.damage * 1.5)
	await get_tree().create_timer(1.5).timeout
	queue_free()
