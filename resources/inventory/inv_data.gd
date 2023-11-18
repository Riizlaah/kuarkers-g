extends Resource
class_name invData

signal inv_updated(inv_d: invData)
signal inv_interact(inv_d: invData, index: int, btn: int)

@export var slotDatas : Array[slotData]
var s_index = null

func onSlotClicked(index: int):
	inv_interact.emit(self, index)
	pass

func find_name(name: String):
	var ret = null
	for i in slotDatas.size():
		if slotDatas[i].item_data == null:
			break
		if slotDatas[i].item_data.name == name:
			s_index = i
			ret = slotDatas[i].duplicate(true)
			return ret
	return ret
func set_s_index(slot_d: slotData):
	if s_index == null:
		return
	slotDatas[s_index] = slot_d
	inv_updated.emit(self)
	s_index = null
	pass

func grab_slotD(index: int):
	var slot_d = slotDatas[index]
	if slot_d.item_data != null:
		slotDatas[index] = slotData.new()
		if slot_d.active == true:
			slotDatas[index].active = true
			slot_d.active = false
		inv_updated.emit(self)
		return slot_d
	else:
		return null

func drop_slotD(g_slotD: slotData, index: int):
	var slot_d = slotDatas[index]
	var r_slot_d
	if slot_d.item_data != null and !slot_d.can_merge(g_slotD):
		slotDatas[index] = g_slotD
		if slot_d.active == true:
			slotDatas[index].active = true
			slot_d.active = false
		r_slot_d = slot_d
	elif slot_d.item_data and slot_d.can_merge(g_slotD):
		#print('h3k')
		slot_d.merge(g_slotD)
		if slot_d.rest > 0:
			var nSlotD = g_slotD
			nSlotD.quantity = slot_d.rest
			r_slot_d = nSlotD
	else:
		slotDatas[index] = g_slotD
		if slot_d.active == true:
			slotDatas[index].active = true
		r_slot_d = null
	inv_updated.emit(self)
	return r_slot_d

func pick_up_slot(slot_d: slotData):
	for index in slotDatas.size():
		if slotDatas[index].item_data != null and slotDatas[index].can_merge(slot_d) == true:
			slotDatas[index].merge(slot_d)
			if slotDatas[index].active == true:
				slotDatas[index].merge(slot_d)
				slotDatas[index].active = true
			else:
				slotDatas[index].merge(slot_d)
			inv_updated.emit(self)
			if slotDatas[index].rest > 0:
				return slotDatas[index].rest
			return true
	
	for index in slotDatas.size():
		if slotDatas[index].item_data == null:
			if slotDatas[index].active == true:
				slotDatas[index] = slot_d
				slotDatas[index].active = true
			else:
				slotDatas[index] = slot_d
			inv_updated.emit(self)
			return true
	return false

func clear_slot():
	var slot_size = slotDatas.size()
	slotDatas.clear()
	for i in range(slot_size):
		slotDatas.append(slotData.new())
	inv_updated.emit(self)

