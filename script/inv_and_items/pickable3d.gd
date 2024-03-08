extends RigidBody3D

var slot_d: SlotData
var picking_up = false

func _ready():
	var item3d = slot_d.item_data.mesh3d.instantiate()
	item3d.rotation_degrees.z = 90
	add_child(item3d)#PICKABLE ITEM WONT MERGE

func _on_pickup(body: Node3D):
	if picking_up == true: return
	picking_up = true
	response(body.pickup(slot_d.duplicate(true)))

func response(what: Array):
	if what[0] == false and what[1] == 0:
		print('not enough')
		picking_up = false
		return
	if what[1] > 0:
		slot_d.stack_count = what[1]
	if what[0] == true: queue_free()
