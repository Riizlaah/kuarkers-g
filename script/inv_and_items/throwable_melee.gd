extends RigidBody3D

const pickup = preload("res://scene/pickable3d.tscn")
var throw_force = 40.0
var direction
var it_data: ItemData
var time = 60
var mult_id
var item_mesh


func _enter_tree():
	set_multiplayer_authority(mult_id)
func throw(dir):
	apply_impulse(dir * throw_force)

func _ready():
	item_mesh = it_data.mesh3d.instantiate()
	item_mesh.rotation_degrees.z = 90
	add_child(item_mesh)

func _process(delta):
	if freeze == true:
		item_mesh.rotate_y(0)
		return
	item_mesh.rotate_y(15 * delta)
	time -= 0.1
	if time <= 0.0:
		queue_free()

func _on_contact(body):
	if body.has_method('take_damage') and body.name.is_valid_int():
		body.take_damage.rpc_id(body.name.to_int(), it_data.melee_damage * 0.8)
	elif body.has_method('take_damage') and !body.name.is_valid_int():
		body.take_damage(it_data.melee_damage * 0.8)
	freeze = true
	await get_tree().create_timer(0.75).timeout
	get_node("/root/WorldLoader").drop_slot.rpc(it_data.unique_name, 1, global_position + Vector3.UP)
	queue_free()
