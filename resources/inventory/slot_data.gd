extends Resource
class_name slotData

const MAX_STACK = 33
@export var item_data : itemData
@export_range(1, MAX_STACK) var quantity = 1: set = set_quantity
var rest = 0
var active: bool = false

func can_merge(other_slot: slotData, for_pickup: bool = false):
	if for_pickup == false:
		return item_data == other_slot.item_data \
	and item_data.stack == true \
	and quantity < MAX_STACK
	else:
		return item_data == other_slot.item_data \
	and item_data.stack == true \
	and quantity < MAX_STACK \
	and quantity + other_slot.quantity <= MAX_STACK

func create_single_slot() -> slotData:
	var n_slot_d : slotData = duplicate()
	n_slot_d.quantity = 1
	quantity -= 1
	return n_slot_d

func merge(other_slot: slotData):
	quantity += other_slot.quantity
	rest = 0
	if quantity > MAX_STACK:
		#hitung sisa hasil penggabungan
		rest = quantity - MAX_STACK
		quantity = MAX_STACK

func set_quantity(val: int):
	quantity = val
	if quantity > 1 and !item_data.stack:
		quantity = 1
	pass
