extends Resource
class_name SlotData

const max_stack = 77
var active: bool = false
@export var item_data: ItemData
@export_range(1, max_stack) var stack_count: int = 1:
	set(val):
		stack_count = val
		if !is_instance_valid(item_data):
			stack_count = 1
			rest = 0
			return
		if stack_count > 1 and !item_data.stack:
			rest = 0
			stack_count = 1
			return
		rest = 0
		if stack_count > max_stack:
			rest = stack_count - max_stack
			stack_count = max_stack
var rest: int = 0

func create_single_slot() -> SlotData:
	var slot_d = duplicate(true)
	slot_d.stack_count = 1
	stack_count -= 1
	return slot_d

func can_merge(other_data: SlotData, for_pickup: bool = false) -> bool:
	if !for_pickup:
		return (item_data.unique_name == other_data.item_data.unique_name) and (item_data.stack == true) and (stack_count < max_stack)
	return item_data == other_data.item_data and item_data.stack == true and stack_count < max_stack and (stack_count + other_data.stack_count) <= max_stack

func merge(other_data: SlotData) -> void:
	stack_count = stack_count + other_data.stack_count
