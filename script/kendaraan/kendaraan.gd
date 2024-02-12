extends VehicleBody3D

const engine_power = 600 * 60
const MAX_STEERING = 10.0
var supir: Variant = null
var penumpang = []
var world_node
var vec_up = Vector3(0, 2, 0)
var loc_pos: Vector3
@onready var ray_cast = $RayCast3D

func _enter_tree():
	world_node = get_node("/root/World")
	set_multiplayer_authority(1)

func _physics_process(delta):
	if supir == null: 
		set_collision_mask_value(3, false)
		return
	if multiplayer.multiplayer_peer.get_unique_id() != get_multiplayer_authority(): return
	steering = move_toward(steering, Input.get_axis("d", "a") * MAX_STEERING, delta * MAX_STEERING)
	engine_force = Input.get_axis("s", "w") * engine_power
	if linear_velocity.length_squared() > 0:#FIXME
		supir.global_position = global_position + vec_up
		for node in penumpang:
			node.global_position = global_position + vec_up

func _on_area_3d_body_entered(body):
	if supir == null:
		body.req_car_join.rpc_id(body.name.to_int(), name, 0)
	else:
		body.req_car_join.rpc_id(body.name.to_int(), name, 1)

func _on_area_3d_body_exited(body):
	body.clear_req.rpc()

@rpc("any_peer","call_local")
func join_car(body_name: String, is_supir: bool):
	var body = world_node.get_node(body_name)
	if is_supir:
		supir = body
		body.ctrl_ui.toggle_oncar_ui.rpc_id(body.name.to_int())
		set_multiplayer_authority(supir.name.to_int())
		body.toggle_exit.rpc_id(name.to_int(), name)
	else:
		penumpang.append(body)
	body.position = global_position + vec_up
	body.set_collision_layer_value(2, false)
	body.set_collision_layer_value(3, false)
	body.rotation_degrees.y = -180
	await get_tree().create_timer(0.05).timeout

@rpc("any_peer", "call_local")
func exit_car(node_name: String):
	var node = world_node.get_node(node_name)
	if node.name == supir.name:
		supir = null
	else:
		penumpang.erase(node)
	node.position = node.global_position + (node.global_transform.basis * Vector3(0, 0, -2))
	await get_tree().create_timer(0.05).timeout
	node.exit_from_car.rpc()
	if supir == null: return
	if node_name == supir.name:
		supir = null
