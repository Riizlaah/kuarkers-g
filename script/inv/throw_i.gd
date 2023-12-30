extends RigidBody3D
class_name ThrowItem

const pickup = preload("res://scene/inv/pick_up.tscn")
var throwForce = 40.0
var slot_d: slotData
var time = 30.0
var direction_r
@onready var sprite = $Sprite3D
@onready var rtw_node = get_node("/root/World")

func _physics_process(delta):
	if freeze == true:
		rotate_y(0)
		return
	rotate_y(15 * delta)
	time -= 0.1
	if time <= 0:
		queue_free()

func throw(direction, slot_d2: slotData):
	sprite.texture = slot_d2.item_data.icon
	slot_d = slot_d2
	direction_r = direction
	apply_impulse(direction_r * throwForce)

func _on_body_entered(body: Node3D):
	if body.has_method("takeDamage"):
		body.takeDamage.rpc_id(body.name.to_int(),slot_d.item_data.type.damage * 1.5)
	freeze = true
	await get_tree().create_timer(1).timeout
	var pickup2 = pickup.instantiate()
	pickup2.slot_d = slot_d
	pickup2.position = global_position
	rtw_node.add_child(pickup2)
	queue_free()
