extends RigidBody3D

@export var slot_d: slotData
@onready var sprite: Sprite3D = $Sprite3D

var pick_up

func _ready():
	sprite.texture = slot_d.item_data.icon

func _on_area3d_entered(body: Node3D):
	if body.has_method("pick_up_slot") == false:
		return
	pick_up = body.pick_up_slot(slot_d)
	match typeof(pick_up):
		TYPE_BOOL:
			del_node()
		TYPE_INT:
			calc_rest()

func calc_rest():
	slot_d.quantity = pick_up
	pass

func del_node():
	if pick_up == true:
		queue_free()

func pick_up_slot(slot_da: slotData):
	if slot_d.can_merge(slot_da):
		slot_d.merge(slot_da)
		if slot_d.rest > 0:
			return slot_d.rest
		return true
	return false
