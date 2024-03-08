extends Resource
class_name InvData

signal inv_interact(inv_data: InvData, idx: int)
signal inv_updated(inv_data: InvData)

@export var slot_datas : Array[SlotData]

func _init(slot_count: int = 1):
	for i in slot_count:
		slot_datas.append(SlotData.new())

func slot_clicked(idx: int):
	inv_interact.emit(self, idx)

func update():
	await RenderingServer.frame_post_draw
	inv_updated.emit(self)

func get_slot(idx: int) -> SlotData:
	return slot_datas[idx]

func find_items(unique_name: String) -> Array:
	var indexes = []
	for i in slot_datas.size():
		if !is_instance_valid(slot_datas[i].item_data): continue
		if slot_datas[i].item_data.unique_name != unique_name: continue
		indexes.append(i)
	return indexes

func merge_same_item(other_d: SlotData):
	var indexes = find_items(other_d.item_data.unique_name)
	if indexes.is_empty(): return [false, 0]
	var rest = 0
	for idx in indexes:
		if slot_datas[idx].can_merge(other_d) and rest == 0:
			slot_datas[idx].merge(other_d)
			update()
			if slot_datas[idx].rest > 0:
				rest = slot_datas[idx].rest
				continue
			return [true, 0]
		slot_datas[idx].stack_count += rest
		update()
		if slot_datas[idx].stack_count > slot_datas[idx].max_stack:
			rest = slot_datas[idx].stack_count - slot_datas[idx].max_stack
			continue
	return [false, rest]

func fill_null_slot(other_d: SlotData):
	for slot in slot_datas:
		if !is_instance_valid(slot.item_data):
			slot.item_data = other_d.item_data
			slot.stack_count = other_d.stack_count
			return [true, 0]
	return [false, 0]

func grab_slot_data(idx: int):
	var slot_d = slot_datas[idx]
	slot_d.active = false
	slot_datas[idx] = SlotData.new()
	update()
	if is_instance_valid(slot_d.item_data): return slot_d
	return null

func drop_slot_data(grabbed_slotd: SlotData, idx: int):
	if !is_instance_valid(slot_datas[idx].item_data):
		slot_datas[idx] = grabbed_slotd
		update()
		return null
	if slot_datas[idx].can_merge(grabbed_slotd) == true:
		slot_datas[idx].merge(grabbed_slotd)
		if slot_datas[idx].rest > 0:
			var slot_d = SlotData.new()
			slot_d.item_data = slot_datas[idx].item_data
			slot_d.stack_count = slot_datas[idx].rest
			update()
			return slot_d
		update()
		return null
	var slot_d = slot_datas[idx]
	slot_datas[idx] = grabbed_slotd
	slot_d.active = false
	update()
	return slot_d
