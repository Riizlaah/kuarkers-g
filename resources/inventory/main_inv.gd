extends invData
class_name MainInv

signal main_slot_change(slot: slotData)

var main_slot: slotData
var main_slot_index: int = 0

func set_main_slot(index: int):
	for inx in slotDatas.size():
		slotDatas[inx].active = false
	main_slot = slotDatas[index]
	slotDatas[index].active = true
	main_slot_index = index
	inv_updated.emit(self)
	main_slot_change.emit(main_slot)

func check_main_slot():
	var slot_d = slotDatas[main_slot_index]
	if main_slot.item_data != slot_d.item_data:
		set_main_slot(main_slot_index)
		inv_updated.emit(self)
		main_slot_change.emit(main_slot)
	if slot_d.item_data == null:
		set_main_slot(main_slot_index)

func slot_empty():
	for inx in slotDatas.size():
		if slotDatas[inx].item_data == null:
			return true
	return false
