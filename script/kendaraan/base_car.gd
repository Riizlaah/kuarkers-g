class_name BaseCar
extends CharacterBody3D

var ray_length = 10.0
var _engine_force: float
var _steering: float
var _wheels: Array[Node]
@export var gravity: float = 30
@export var test_engine: float = 0.0
@export var ray_cast: RayCast3D

func _ready():
	_engine_force = test_engine
	var nodes = get_children()
	for node in nodes:
		if node.name.begins_with("whl"):
			_wheels.append(node)

func _physics_process(delta):
	if _steering != 0.0:
		rotate_y(_steering * delta)
	velocity = (Vector3.FORWARD * _engine_force)
	if !is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()

func go(direction: float):
	_engine_force = direction

func turn(rot: float):
	_steering = rot

func stop():
	_engine_force = 0

