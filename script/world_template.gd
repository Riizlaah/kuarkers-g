class_name WorldTemplate
extends Node3D


func players_added():
	pass

func save_world() -> Dictionary: return {}

func set_world_spawn():
	var ray = RayCast3D.new()
	ray.target_position = Vector3(0, -400, 0)
	ray.position.y = 200
	add_child(ray)
	await get_tree().create_timer(0.5).timeout
	if ray.is_colliding(): get_parent().world_spawn = ray.get_collision_point() + Vector3(0, 8.5, 0)
	else: get_parent().world_spawn = Vector3(0, 27.5, 0)
	ray.queue_free()
