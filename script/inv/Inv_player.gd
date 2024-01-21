extends Control

const pickup = preload("res://scene/inv/pick_up.tscn")
const throw_i = preload("res://scene/inv/throw_i.tscn")
var active_slot: slotData
var mainItem
var toggle_s := false
#var heal_time

@onready var Minv_data = $Main_Inv
@onready var Sinv_data: PanelContainer = $Sec_Inv
@onready var act_hud = $Active_hud
@onready var act_lb = $Active_hud/Label
@onready var act_slot = $Active_hud/Slot
@onready var rt_node = get_tree().get_root()
@onready var charr: Player = $"../.."
@onready var camera = $"../../Badan/Kepala/Camera3D"
@onready var r_btn_texture = $"../Right/TextureRect"
@onready var c_texture = $"../TextureRect"
@onready var vignette = $"../Vignette"

@export var main_inv : MainInv: set = sMSlot
@export var sec_inv : invData
@export var texture_arr: Array[Texture]


func _ready():
	var ctrl = $".."
	rt_node = rt_node.get_node("/root/World")
	Minv_data.setup_slot(main_inv)
	Sinv_data.setup_slot(sec_inv)
	main_inv.main_slot_change.connect(ch_main_slot)
	main_inv.inv_interact.connect(on_inv_interact)
	sec_inv.inv_interact.connect(on_inv_interact)
	ctrl.right_click.connect(on_right_pressed)
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
		mainItem = null
	else:
		charr.set_onhand_item(slot)
		mainItem = main_inv.main_slot.item_data
		charr.set_properti(slot.item_data.type)
		if mainItem.type is GunType or mainItem.type is RPGType:
			charr.weapon_ray.show()
			charr.update_ammo()
			r_btn_texture.texture = texture_arr[0]
		else:
			charr.weapon_ray.hide()
			charr.ammo_lb.hide()
			if toggle_s == true:
				camera.fov = 75
				c_texture.texture = texture_arr[3]
				vignette.hide()
			r_btn_texture.texture = texture_arr[2]


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
	npickup.position = -charr.global_transform.basis.z + (charr.global_transform * Vector3(0,0,-1))
	rt_node.add_child(npickup)
	if active_slot.quantity == 0:
		active_slot = null
	update_active_slot()


func _on_rm_all_pressed():
	var npickup = pickup.instantiate()
	npickup.slot_d = active_slot
	npickup.position = -charr.global_transform.basis.z + (charr.global_transform * Vector3(0,0,-1))
	rt_node.add_child(npickup)
	active_slot = null
	update_active_slot()
func _on_sec_inv_visibility_changed():
	if active_slot != null:
		_on_rm_all_pressed()


func on_right_pressed():
	if mainItem == null:
		return
	if mainItem.type is GunType or mainItem.type is RPGType:
		toggle_scope()
	elif mainItem.type is MeleeType:
		var throwItem: RigidBody3D = throw_i.instantiate()
		throwItem.position = -camera.global_transform.basis.z + (camera.global_transform * Vector3(0,0,-1))
		rt_node.add_child(throwItem)
		var slot_d = main_inv.main_slot
		slot_d.active = false
		throwItem.throw(-camera.global_transform.basis.z, slot_d)
		main_inv.slotDatas[main_inv.main_slot_index] = slotData.new()
		main_inv.check_main_slot()
	elif mainItem.type is FoodType:
		#makan
		if charr.currentHealth == 100:
			return
		charr.anim.play("eat")
		await get_tree().create_timer(1.5).timeout
		var data: FoodType = mainItem.type
		charr.heal(data.heal)
		#kurangi
		main_inv.slotDatas[main_inv.main_slot_index].quantity -= 1
		if main_inv.slotDatas[main_inv.main_slot_index].quantity < 0:
			main_inv.slotDatas[main_inv.main_slot_index] = slotData.new()
		#update
		main_inv.check_main_slot()
	elif mainItem.type is DrinkType:
		#minum & efek
		charr.anim.play("eat")
		await get_tree().create_timer(1.5).timeout
		var data: DrinkType = mainItem.type
		charr.take_effect(data.spd_tmp, data.dmg_tmp, data.time_eff)
		#kurangi
		main_inv.slotDatas[main_inv.main_slot_index].quantity -= 1
		if main_inv.slotDatas[main_inv.main_slot_index].quantity < 0:
			main_inv.slotDatas[main_inv.main_slot_index] = slotData.new()
		#update
		main_inv.check_main_slot()
		pass

func toggle_scope():
	toggle_s = !toggle_s
	if toggle_s == true:
		c_texture.texture = texture_arr[1]
		camera.fov = mainItem.type.cam_fov
		vignette.show()
	else:
		c_texture.texture = texture_arr[3]
		camera.fov = 75
		vignette.hide()

func search_ammo():
	var main_r = main_inv.find_name("Ammo")
	if main_r != null:
		return main_r
	else:
		return sec_inv.find_name("Ammo")
		#sampai sini

func update_ammo():
	main_inv.inv_updated.emit(main_inv)
	sec_inv.inv_updated.emit(sec_inv)
	return

func set_main_s():
	main_inv.set_main_slot(0)

func clear_slot():
	main_inv.clear_slot()
	sec_inv.clear_slot()
	set_main_s()
