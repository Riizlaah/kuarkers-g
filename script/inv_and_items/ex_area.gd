extends Area3D

#var effect
var damage: int
var radius: float
@onready var colls = $Colls
@onready var animation = $Animation
@export var shape: SphereShape3D

func _enter_tree():
	shape = SphereShape3D.new()
	shape.radius = radius

func _ready():
	colls.shape = shape
	animation.play("explode")
	$ExplodeEffect.play()
	await get_tree().create_timer(0.5).timeout
	var nodes = get_overlapping_bodies()
	for node in nodes:
		if node.name.is_valid_int():
			node.take_damage.rpc_id(node.name.to_int(), damage)
			continue
		node.take_damage(damage)
	queue_free()
