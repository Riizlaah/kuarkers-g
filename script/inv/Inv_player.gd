extends Control

const pickup = preload("res://scene/inv/pick_up.tscn")
var active_slot: slotData
var mainItem: itemData

@onready var Minv_data = $MainInventory
@onready var Sinv_data: PanelContainer = $SecInventory
@onready var act_hud = $Active_hud
@onready var act_lb = $Active_hud/Label
@onready var act_slot = $Active_hud/Slot
@onready var rt_node = get_tree().get_root()
@onready var charr = $"../.."
@onready var camera = $"../../Badan/Kepala/Camera3D"

@export var main_inv : MainInv: set = sMSlot
@export var sec_inv : invData

func _ready():
	rt_node = rt_node.get_node("/root/World")
	Minv_data.setup_slot(main_inv)
	Sinv_data.setup_slot(sec_inv)
	main_inv.main_slot_change.connect(ch_main_slot)
	main_inv.inv_interact.connect(on_inv_interact)
	sec_inv.inv_interact.connect(on_inv_interact)
	#main_inv.set_main_slot(0)

func sMSlot(inv_d: MainInv):
	main_inv = inv_d
	if inv_d.slotDatas.size() > 3:
		var FArr = inv_d.slotDatas.slice(0,3)
		main_inv.slotDatas = FArr
	pass

func _OnInv_pressed():
	Sinv_data.visible = !Sinv_data.visible
	pass

func on_inv_interact(inv_d: invData, index: int) -> void:
	match active_slot:
		null:
			if Sinv_data.visible == false:
				inv_d.set_main_slot(index)
			else:
				active_slot = inv_d.grab_slotD(index)
		_:
			if Sinv_data.visible == false:
				inv_d.set_main_slot(index)
			else:
				active_slot = inv_d.drop_slotD(active_slot, index)
	update_active_slot()
	main_inv.check_main_slot()
	pass

func pick_up_slot(slot_d: slotData):
	if main_inv.slot_empty() == true:
		var ret = main_inv.pick_up_slot(slot_d)
		main_inv.check_main_slot()
		return ret
	else:
		return sec_inv.pick_up_slot(slot_d)

func ch_main_slot(slot: slotData):
	if slot.item_data == null:
		charr.reset_onhand_item()
	else:
		charr.set_onhand_item(slot)
		#charr.set_properti(slot.item_data.type)
	mainItem = main_inv.main_slot.item_data


func update_active_slot():
	if active_slot != null:
		act_hud.show()
		act_lb.text = active_slot.item_data.name
		act_slot.set_slotD(active_slot)
	else:
		act_hud.hide()
	pass

func _on_rm_single_pressed():
	var npickup = pickup.instantiate()
	npickup.slot_d = active_slot.create_single_slot()
	npickup.position = -charr.global_transform.basis.z + charr.global_position + Vector3(0,0,-1)
	rt_node.add_child(npickup)
	if active_slot.quantity == 0:
		active_slot = null
	update_active_slot()


func _on_rm_all_pressed():
	var npickup = pickup.instantiate()
	npickup.slot_d = active_slot
	npickup.position = -charr.global_transform.basis.z + charr.global_position + Vector3(0,0,-1)
	rt_node.add_child(npickup)
	active_slot = null
	update_active_slot()
func _on_sec_inv_visibility_changed():
	if active_slot != null:
		_on_rm_all_pressed()


func _on_left_pressed():
	pass#main_inv.main_slot.item_data
func _on_right_pressed():
	if mainItem.type is MeleeType:
		print('yes')
		if mainItem.type.throwable != false:
			return
		var throw_i = ThrowItem.new()
		throw_i.position = -charr.global_transform.basis.z + charr.global_position + Vector3(0,0,-1)
		throw_i.throw(-camera.global_transform.basis.z + camera.global_position + Vector3(0,0,-1), mainItem)
		main_inv.slotDatas[main_inv.main_slot_index] = slotData.new()
		main_inv.check_main_slot()
		
#	match mainItem.type:
#		ItemType:


#	if main_inv.main_slot.item_data == null:
#		return
#	main_inv.main_slot.item_data.type.r_click([
#		charr, 
#		main_inv.main_slot.item_data, 
#		main_inv, 
#		sec_inv
#		])

func _on_timer_timeout():
	main_inv.set_main_slot(0)
