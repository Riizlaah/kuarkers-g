extends PanelContainer

@export var inv_data: InvData
@onready var gcont = $Mcont/Gcont

const slot_iface = preload("res://scene/slot_interface.tscn")

func setup_inv_connection():
	inv_data.inv_updated.connect(inv_updated)
	inv_updated(inv_data)

func inv_updated(inv_d: InvData):
	for node in gcont.get_children(): node.queue_free()
	for slot in inv_d.slot_datas:
		var new_slot = slot_iface.instantiate()
		new_slot.active = slot.active
		gcont.add_child(new_slot)
		if is_instance_valid(slot.item_data):
			new_slot.set_slot_d(slot)
		new_slot.slot_clicked.connect(slot_clicked)

func slot_clicked(idx: int):
	inv_data.inv_interact.emit(inv_data, idx)
