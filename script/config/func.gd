#extends Node

func is_em_slot(arr: Array[slotData]):
	for inx in arr.size():
		if arr[inx].item_data == null:
			return inx
	return false

