extends InvData
class_name MainInv

signal main_slot_changed(slot_d: SlotData)

var main_slot: SlotData
var main_slot_idx: int

func set_main_slot(idx: int):
	main_slot = slot_datas[idx].duplicate(true)
	for slot in slot_datas: slot.active = false
	main_slot_idx = idx
	slot_datas[idx].active = true
	main_slot_changed.emit(slot_datas[idx])
	await RenderingServer.frame_post_draw
	inv_updated.emit(self)

func check_main_slot():
	var main_s = slot_datas[main_slot_idx]
	if (main_s != main_slot) or (main_s.item_data != main_slot.item_data) or (main_s.stack_count != main_slot.stack_count):
		set_main_slot(main_slot_idx)

func remove_main_slot():
	main_slot.item_data = null
	slot_datas[main_slot_idx].item_data = null
	check_main_slot()
