extends PanelContainer

const slot_s = preload("res://scene/inv/slot.tscn")

@onready var it_grid = $MarginContainer/ItemGrid

func setup_slot(inv_d: invData):
	inv_d.inv_updated.connect(pop_it_grid)
	pop_it_grid(inv_d)
	pass

func pop_it_grid(inv_data: invData):
	for child in it_grid.get_children():
		child.queue_free()
	for slot_d in inv_data.slotDatas:
		var slot = slot_s.instantiate()
		it_grid.add_child(slot)
		slot.slotClicked.connect(inv_data.onSlotClicked)
		slot.activate(slot_d)
		if slot_d.item_data != null:
			slot.set_slotD(slot_d)
	pass

