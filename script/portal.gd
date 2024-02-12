class_name Portal
extends Node3D

@export var destination: Portal

func _on_area_3d_body_entered(body: Node3D):
	var glob_pos = (destination.global_transform.basis * (destination.global_position) +(body.global_transform.basis * Vector3(0,0,-1.5)))
	body.global_position = glob_pos
