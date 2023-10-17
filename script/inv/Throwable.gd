extends RigidBody3D
class_name Throwable

const pick_up = preload("res://scene/inv/pick_up.tscn")
const ex_area = preload("res://scene/ExArea.tscn")

@onready var colls = $Colls
@onready var sprite = $Sprite3D
@onready var time_rate = 30.0 / 300.0

var item_d: itemData
var time = 30

func set_item(item: itemData):
	sprite.texture = item.onhand_texture
	sprite.scale = Vector3(item.onhand_scale, item.onhand_scale, item.onhand_scale)
	match item.name:
		"Kapak":
			colls.shape.set("size", Vector3(0.5, 2.3, 1.2))
		"Granat":
			colls.shape = SphereShape3D.new()
	item_d = item

func _process(delta):
	if item_d.name == "Granat":
		time -= time_rate * delta
	if time <= 0.0:
		var ex_point = global_position
		var rt_node = get_node("/root/World")
		var exa = ex_area.instantiate()
		exa.global_position = ex_point
		rt_node.add_child(exa)
		exa.explode()
		queue_free()
	pass

func _on_body_entered(_body):
	if item_d.name == "Granat":
		return
	await get_tree().create_timer(2).timeout
	var pickup = pick_up.instantiate()
	pickup.slot_d = slotData.new()
	pickup.slot_d.set("item_data", item_d)
	pickup.position = global_position
	get_node("/root/World").add_child(pickup)
	queue_free()
