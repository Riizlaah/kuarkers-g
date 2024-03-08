extends CharacterBody3D

signal inv_set

const JUMP_VELOCITY = 10
const MAX_HP = 300.0
const dont_walk = ['eat', 'attack_null', 'attack_melee']
const normal_speed = 10.0

var SPEED = 10.0
var gravity = 10
var senv: float
var deg89 = deg_to_rad(89)
var player_name: String
var color: Color
@export var hp := MAX_HP
var old_velo := 0.0
var gravity_thres := 12
var hurt_tween: Tween
var uniqid: int
var main_inv: MainInv
var sec_inv: InvData
var inv_opened: bool = false
var paused: bool = false
var current_view = 0
var main_item: ItemData
var cooldown_finished: bool = true
var is_reloading: bool = false
var is_reloading2: bool = false
var running: bool = false
var bullet_shooted = 0
var calc_speed = 8.0
var is_desktop = false
var die: bool = false
var chat_visib := false

@export var gradient_hp: Gradient

@onready var head = $Armature/Skeleton3D/Head
var cam: Camera3D
@onready var cams = [
	$Armature/Skeleton3D/Head/Camera3D,
	$Armature/Skeleton3D/Head/SpringArm3D/Camera3D2,
	$Armature/Skeleton3D/Head/SpringArm3D2/Camera3D2
]
@onready var label_3d = $Armature/Skeleton3D/Head/Label3D
@onready var cube = $Armature/Skeleton3D/Cube
@onready var hpbar = $Layer1/Control/Panel/Hbox/Vbox/Hbox/ColorRect/hpbar
@onready var hpbar_lb = $Layer1/Control/Panel/Hbox/Vbox/Hbox/hpbar_lb
@onready var layer_1 = $Layer1
@onready var pause_panel = $Layer1/Control/PausePanel
@onready var main_inv_node = $Layer1/Control/Panel/Hbox/MainInv
@onready var sec_inv_node = $Layer1/Control/Panel2/SecInv
@onready var sec_inv_panel = $Layer1/Control/Panel2
@onready var item_label = $Layer1/Control/ItemName
@onready var onhand_item = $Armature/Skeleton3D/Handup/Hand/Node3D
@onready var pos_label = $Layer1/Control/PosLabel
@onready var animation: AnimationPlayer = $Animation
@onready var item_menu = $Layer1/Control/Panel2/Panel
@onready var item_menu_slot = $Layer1/Control/Panel2/Panel/SlotInterface
@onready var ray_cast = $Armature/Skeleton3D/Head/Camera3D/RayCast3D
@onready var timer = $Timer
@onready var muzzle = $Armature/Skeleton3D/Handup/Hand/FMuzzle
@onready var ammo_lb = $Layer1/Control/Panel/Hbox/Vbox/Label
@onready var death_sc = $death_sc
@onready var chat_layer = $ChatLayer
@onready var shoot_effect = $ShootEffect
@onready var eat_effect = $EatEffect
@onready var drink_effect = $DrinkEffect
@onready var slash_sword = $SlashSword
@onready var melee_throw = $MeleeThrow
@onready var rocket_launch = $RocketLaunch
@onready var grenade_throw = $GrenadeThrow

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	uniqid = name.to_int()

func _ready():
	layer_1.hide()
	label_3d.text = player_name
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	cube.material_override = mat
	main_inv = MainInv.new(3)
	sec_inv = InvData.new(18)
	inv_set.emit(self)
	if multiplayer.get_unique_id() != get_multiplayer_authority(): return
	if OS.get_name() != "Android":# sesuaikan ukuran tombol-tombol ini...
		get_node("Layer1/Control/LC").hide()
		get_node("Layer1/Control/RC").hide()
		get_node("Layer1/Control/jump").hide()
		get_node("Layer1/Control/RUN").hide()
		get_node("Layer1/Control/Panel/Hbox/Button").hide()
		get_node("Layer1/Control/VJ").hide()
		get_node("Layer1/Control/Pause").hide()
		get_node("Layer1/Control/Chat").hide()
		is_desktop = true
	main_inv_node.inv_data = main_inv
	sec_inv_node.inv_data = sec_inv
	main_inv.main_slot_changed.connect(main_slot_changed)
	main_inv_node.setup_inv_connection()
	sec_inv_node.setup_inv_connection()
	main_inv.inv_interact.connect(inv_interact)
	sec_inv.inv_interact.connect(inv_interact)
	cam = cams[0]
	cam.current = true
	get_node("Armature/Skeleton3D/Head/Camera3D/AudioListener3D").current = true
	layer_1.show()
	senv = Settings.senv
	for camera in cams:
		camera.far = Settings.view_dist
	update_hp()
	chat_layer.get_node("Panel").chat_manager = get_parent().get_node("ChatManager")

func _process(_delta):
	pos_label.text = "POS: "+str(Vector3i(position))

func _physics_process(delta: float):#add: buat lebih baik(ikon dll.)
	if multiplayer.get_unique_id() != get_multiplayer_authority(): return
	if Input.is_action_just_pressed("jump") and is_on_floor() and !paused:
		if !chat_layer.visible: 
			velocity.y = JUMP_VELOCITY
	var input_dir = Input.get_vector("a", "d", "w", "s")
	if paused or chat_layer.visible: input_dir = Vector2.ZERO
	if not is_on_floor(): velocity.y -= gravity * delta
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * calc_speed
	velocity.z = direction.z * calc_speed
	if head.rotation_degrees.y != 0.0 and velocity != Vector3.ZERO:
		rotate_y(head.rotation.y)
		head.rotation.y = 0.0
	move_and_slide()
	velocity = velocity
	if old_velo < 0:
		var diff = velocity.y - old_velo
		if diff > gravity_thres: take_damage(roundi(diff - gravity_thres))
	old_velo = velocity.y
	animate(input_dir)

func animate(input_dir: Vector2):
	var curr_anim = animation.current_animation
	if Vector2.ZERO != input_dir and (!dont_walk.has(curr_anim)):
		if curr_anim != "walk": animation.play("walk")
	elif animation.is_playing() and curr_anim != "walk": pass
	else: animation.play("idle")

func _input(event: InputEvent):
	if multiplayer.get_unique_id() != get_multiplayer_authority(): return
	var in_chat = chat_layer.visible
	if event is InputEventScreenDrag and !paused and !in_chat:
		head.rotation.z = 0
		head.rotation_degrees.x += (-event.relative.y) * get_process_delta_time() * senv
		head.rotation.x = clamp(head.rotation.x, -deg89, deg89)
		head.rotation_degrees.y += (-event.relative.x) * get_process_delta_time() * senv
		if head.rotation_degrees.y  >= 80 or head.rotation_degrees.y <= -80: rotate_y(deg_to_rad(-event.relative.x))
		head.rotation.y = clamp(head.rotation.y, -deg89, deg89)
	if Input.is_action_pressed("pause") and !in_chat: _on_paused()
	if in_chat or paused: return
	if Input.is_action_pressed("chat"): _on_chat_pressed()
	if Input.is_action_pressed("open_inv"): _on_open_inv()
	if Input.is_action_pressed("change_view"): _change_view()
	if Input.is_action_pressed("drop_slot"): drop_main_slot()
	if Input.is_action_pressed("lc"): left_click()
	if Input.is_action_pressed("rc"): right_click()
	if Input.is_action_pressed("tg_run"): _on_run_toggled(!running)

func heal(healed_hp: int):
	hp = ceil(clamp(hp + healed_hp, 0, MAX_HP))
	update_hp()
@rpc("any_peer", "call_local")
func take_damage(dmg: int):
	hp = floor(clamp(hp - dmg, 0, MAX_HP))
	update_hp()
	hurt()
	if hp == 0: death.rpc()

func hurt():
	pass

func update_hp():
	hpbar.color = gradient_hp.sample(hp / MAX_HP)
	hpbar.scale.x = hp / MAX_HP
	hpbar_lb.text = "%s HP" % hp

@rpc("call_local")
func death():
	layer_1.hide()
	set_process(false)
	set_physics_process(false)
	hide()
	if name.to_int() != multiplayer.get_unique_id(): return
	death_sc.show()

func _on_respawn():
	hp = MAX_HP
	update_hp()
	position = Vector3.ZERO
	layer_1.show()
	death_sc.hide()
	set_process(true)
	set_physics_process(true)
	show()

func _on_back_pressed():
	if multiplayer.is_server():
		multiplayer.server_disconnected.emit()
		return
	get_parent().disconnect_player.rpc_id(1, uniqid)
	multiplayer.multiplayer_peer = null
	GManager.players.clear()
	get_tree().change_scene_to_packed(get_parent().main_menu)

func _on_paused():
	paused = !paused
	if paused: pause_panel.show()
	else: pause_panel.hide()#ADD SOUND EFFECT & MORE SYNC.

func _change_view():
	current_view = (current_view + 1) % cams.size()
	cam = cams[current_view]
	cam.current = true

func _on_run_toggled(toggled_on: bool):
	running = toggled_on
	if running == true: calc_speed = SPEED * 2
	else: calc_speed = SPEED

func apply_cooldown(cooldown: float):
	if cooldown == 0.0 or cooldown == 0: return
	cooldown_finished = false
	timer.wait_time = cooldown
	timer.start()

func _on_cooldown_finished():
	cooldown_finished = true

func hand_up():
	var hand = get_node("Armature/Skeleton3D/Handup/Hand")
	hand.override_pose = true
	hand.rotation_degrees.x = 90
	hand.rotation_degrees.y = -10
	ray_cast.target_position.z = main_item.max_range

func handup_up90():
	var hand = get_node("Armature/Skeleton3D/Handup")
	hand.override_pose = true
	hand.rotation_degrees.x = -90
	hand.rotation_degrees.y = -10
	ray_cast.target_position.z = 7

func handup_down():
	var hand = get_node("Armature/Skeleton3D/Handup")
	hand.override_pose = false

func hand_down():
	var hand = get_node("Armature/Skeleton3D/Handup/Hand")
	hand.override_pose = false
	ray_cast.target_position.z = 7

func left_click():
	if !cooldown_finished: return
	if is_instance_valid(main_item): apply_cooldown(main_item.cooldown)
	if(main_item is MeleeItem):
		var obj = ray_cast.get_collider()
		animation.play("attack_melee")
		slash_sword.play()
		if !is_instance_valid(obj): return
		if !obj.name.is_valid_int(): obj.take_damage(main_item.melee_damage, name)
		else: obj.take_damage.rpc_id(obj.name.to_int(), main_item.melee_damage)
	elif(main_item is GunItem):
		bullet_shooted = main_item.rate_of_fire
		shoot_bullet.rpc()
	else:
		apply_cooldown(1)
		punch()

func right_click():
	if !cooldown_finished: return
	if(main_item is MeleeItem):
		if !main_item.throwable_melee: return
		melee_throw.play()
		get_parent().throw_item.rpc(main_item.unique_name, -cams[0].global_basis.z + (cams[0].global_transform * Vector3(0, 0, -1.5)), -cams[0].global_basis.z, name.to_int())
		main_inv.remove_main_slot()
		main_inv.check_main_slot()
	elif(main_item is FoodItem):
		eat()
	elif(main_item is DrinkItem):
		drink()
	elif(main_item is ExplodableItem):
		apply_cooldown(0.5)
		grenade_throw.play()
		get_parent().throw_grenade.rpc(main_item.unique_name, -cams[0].global_basis.z + (cams[0].global_transform * Vector3(0, 0, -1.5)), -cams[0].global_basis.z)
		var slot_d = main_inv.slot_datas[main_inv.main_slot_idx]
		if slot_d.stack_count < 1: main_inv.remove_main_slot()
		slot_d.stack_count -= 1
		main_inv.check_main_slot()
	elif(main_item is ExLauncherItem):
		apply_cooldown(main_item.cooldown)
		shoot_rocket()
	else: pass

func shoot_rocket():
	if is_reloading2 == true: return
	if main_item.ammo < 1:
		is_reloading2 = true
		update_rocket()
		await get_tree().create_timer(main_item.cooldown).timeout
		reload_rocket()
		is_reloading2 = false
		update_rocket()
		return
	main_item.ammo -= 1
	rocket_launch.play()
	get_parent().launch_rocket.rpc(-cams[0].global_basis.z + (cams[0].global_transform * Vector3(0, 0, -1.5)), -cams[0].global_basis.z)
	update_ammo()

func reload_rocket():
	var rocket
	var rocket_dat = search_rocket()
	if rocket_dat[0] == -1: return
	if rocket_dat[1] == "m":
		rocket = main_inv.get_slot(rocket_dat[0])
		rocket.stack_count -= 1
		if rocket.stack_count < 1:
			main_inv.slot_datas[rocket_dat[0]] = SlotData.new()
		main_item.ammo = main_item.max_ammo
		await RenderingServer.frame_post_draw
		main_inv.update()
		return
	rocket = sec_inv.get_slot(rocket_dat[0])
	rocket.stack_count -= 1
	if rocket.stack_count < 1: main_inv.slot_datas[rocket_dat[0]] = SlotData.new()
	main_item.ammo = main_item.max_ammo
	await RenderingServer.frame_post_draw
	sec_inv.update()

@rpc("call_local")
func drink():
	apply_cooldown(main_item.cooldown)
	animation.play("eat")
	drink_effect.play()
	await get_tree().create_timer(main_item.cooldown).timeout
	SPEED *= 8
	_on_run_toggled(running)
	get_node("SpeedTimer").start()
	var drink_i = main_inv.slot_datas[main_inv.main_slot_idx]
	drink_i.stack_count -= 1
	if drink_i.stack_count < 1: main_inv.remove_main_slot()
	main_inv.update()

func _on_speed_effect_timeout():
	SPEED = normal_speed
	_on_run_toggled(running)
@rpc("call_local")
func eat():
	apply_cooldown(main_item.cooldown)
	animation.play("eat")
	eat_effect.play()
	await get_tree().create_timer(main_item.cooldown).timeout
	heal(main_item.heal)
	var food = main_inv.slot_datas[main_inv.main_slot_idx]
	food.stack_count -= 1
	if food.stack_count < 1: main_inv.remove_main_slot()
	main_inv.update()
@rpc("call_local")
func punch():
	var obj = ray_cast.get_collider()
	animation.play("attack_null")
	if !is_instance_valid(obj): return
	if !obj.name.is_valid_int(): obj.take_damage(30, name)
	else: obj.take_damage.rpc_id(obj.name.to_int(), 30)

@rpc("call_local")
func shoot_bullet():
	if !Input.is_action_pressed("lc"): return
	if is_reloading == true: return
	if main_item.ammo < 1:
		is_reloading = true
		update_ammo()
		await get_tree().create_timer(main_item.reload_time).timeout
		reload()
		is_reloading = false
		update_ammo()
		return
	main_item.ammo -= 1
	update_ammo()
	if main_item.rate_of_fire > 1:
		await get_tree().create_timer(1.0 / main_item.rate_of_fire).timeout
	if ray_cast.is_colliding():
		var obj = ray_cast.get_collider()
		if obj.name.is_valid_int(): obj.take_damage.rpc_id(obj.name.to_int(), main_item.bullet_damage)
		else: obj.take_damage(main_item.bullet_damage, name)
	animate_shoot()
	bullet_shooted -= 1
	if bullet_shooted == 0:
		return
	shoot_bullet.rpc()

func animate_shoot():
	muzzle.show()
	shoot_effect.play()
	await get_tree().create_timer(0.1).timeout
	shoot_effect.stop()
	muzzle.hide()

func update_rocket():
	if !is_reloading2:
		ammo_lb.text = str("Rocket: ", main_item.ammo, "/", main_item.max_ammo)
		return
	ammo_lb.text = "Reloading..."

func update_ammo():
	if !is_reloading:
		ammo_lb.text = "Ammo: "+str(main_item.ammo, "/", main_item.max_ammo)
		return
	ammo_lb.text = "Reloading..."

func reload():
	var ammo
	var ammo_dat = search_ammo()
	if ammo_dat[0] == -1: return
	if ammo_dat[1] == "m":
		ammo = main_inv.get_slot(ammo_dat[0])
		ammo.stack_count -= 1
		if ammo.stack_count < 1:
			main_inv.slot_datas[ammo_dat[0]] = SlotData.new()
		main_item.ammo = main_item.max_ammo
		await RenderingServer.frame_post_draw
		main_inv.update()
		return
	ammo = sec_inv.get_slot(ammo_dat[0])
	ammo.stack_count -= 1
	if ammo.stack_count < 1: main_inv.slot_datas[ammo_dat[0]] = SlotData.new()
	main_item.ammo = main_item.max_ammo
	await RenderingServer.frame_post_draw
	sec_inv.update()

func search_ammo():
	var ammos = main_inv.find_items("bullet_ammo")
	if !ammos.is_empty(): return [ammos[0], "m"]
	ammos = sec_inv.find_items("bullet_ammo")
	if !ammos.is_empty(): return [ammos[0], "s"]
	return [-1]

func search_rocket():
	var rockets = main_inv.find_items("rocket_ammo")
	if !rockets.is_empty(): return [rockets[0], "m"]
	rockets = sec_inv.find_items("rocket_ammo")
	if !rockets.is_empty(): return [rockets[0], "s"]
	return [-1]

#INVENTORY SYSTEM
var active_slot: SlotData = null
func inv_interact(inv_d: InvData, idx: int):
	if !is_instance_valid(active_slot):
		if !sec_inv_panel.visible:
			inv_d.set_main_slot(idx)
			return
		active_slot = inv_d.grab_slot_data(idx)
		check_grabbed_slot()
		main_inv.check_main_slot()
		return
	if !sec_inv_panel.visible:
		inv_d.set_main_slot(idx)
		return
	active_slot = inv_d.drop_slot_data(active_slot, idx)
	check_grabbed_slot()
	main_inv.check_main_slot()

func check_grabbed_slot():
	if active_slot != null:
		item_menu_slot.set_slot_d(active_slot)
		item_menu.show()
		return
	item_menu.hide()

func set_inv_data(items: Array):
	for i in 3:
		var item = items.pick_random()
		main_inv.slot_datas[i].item_data = item.duplicate(true) if is_instance_valid(item) else item
		main_inv.slot_datas[i].stack_count = randi_range(1, 77)
	if multiplayer.get_unique_id() != get_multiplayer_authority(): return
	var sync_dat = []
	for slot in main_inv.slot_datas:
		sync_dat.append({
			'item': slot.item_data.unique_name if is_instance_valid(slot.item_data) else 'null',
			'stack_count': slot.stack_count})
	sync_inv.rpc(sync_dat)
	await RenderingServer.frame_post_draw
	main_inv.set_main_slot(0)

@rpc("call_local")
func sync_inv(dats):
	var items = get_parent().items
	for i in 3:
		main_inv.slot_datas[i].item_data = items[dats[i].item]
		main_inv.slot_datas[i].stack_count = dats[i].stack_count
	await RenderingServer.frame_post_draw
	main_inv.set_main_slot(0)

func _on_open_inv():
	inv_opened = !inv_opened
	if inv_opened: sec_inv_panel.show()
	else: sec_inv_panel.hide()

func no_item():
	item_label.hide()
	for child in onhand_item.get_children(): child.queue_free()
	onhand_item.hide()

func main_slot_changed(slot_d: SlotData):
	local_main_slot_change.rpc(main_inv.main_slot_idx)
	no_item()
	main_item = null
	if !is_instance_valid(slot_d.item_data):
		ammo_lb.hide()
		handup_down()
		hand_down()
		return
	main_item = slot_d.item_data
	if(main_item is GunItem):
		update_ammo()
		ammo_lb.show()
		handup_down()
		hand_up()
	elif(main_item is ExLauncherItem):
		update_rocket()
		ammo_lb.show()
		handup_up90()
		hand_down()
	else:
		ammo_lb.hide()
		handup_down()
		hand_down()
	onhand_item.show()
	item_label.show()
	item_label.text = main_item.name
	var item_3d = main_item.mesh3d.instantiate()
	onhand_item.add_child(item_3d)
	item_3d.position = main_item.pos
	item_3d.rotation = main_item.rot

@rpc("call_local")
func local_main_slot_change(idx: int):
	var slot_d = main_inv.get_slot(idx)
	no_item()
	main_item = null
	if !is_instance_valid(slot_d.item_data):
		handup_down()
		hand_down()
		return
	main_item = slot_d.item_data
	if(main_item is GunItem):
		hand_up()
	elif(main_item is ExLauncherItem):
		handup_up90()
	else:
		handup_down()
		hand_down()
	onhand_item.show()
	var item3d = main_item.mesh3d.instantiate()
	onhand_item.add_child(item3d)
	item3d.position = main_item.pos
	item3d.rotation = main_item.rot

func pickup(slot_d: SlotData):
	var ret = main_inv.merge_same_item(slot_d)
	main_inv.check_main_slot()
	if ret[0] == true: return ret
	if ret[1] > 0: slot_d.stack_count = ret[1]
	ret = sec_inv.merge_same_item(slot_d)
	if ret[0] == true: return ret
	if ret[1] > 0: slot_d.stack_count = ret[1]
	ret = main_inv.fill_null_slot(slot_d)
	main_inv.check_main_slot()
	if ret[0] == true: return ret
	ret = sec_inv.fill_null_slot(slot_d)
	if ret[0] == true: return ret
	return [false, 0]

func drop_active_slot():
	if !is_instance_valid(active_slot): return
	var slot_d = active_slot
	var pos = -global_transform.basis.z + (global_transform * Vector3(0, 0, -3.5))
	get_parent().drop_slot.rpc(slot_d.item_data.unique_name, slot_d.stack_count, pos)
	active_slot = null
	check_grabbed_slot()

func drop_single_active_slot():
	var slot_d = active_slot.create_single_slot()
	var pos = -global_transform.basis.z + (global_transform * Vector3(0, 0, -3.5))
	get_parent().drop_slot.rpc(slot_d.item_data.unique_name, slot_d.stack_count, pos)
	if active_slot.stack_count == 0: active_slot = null
	check_grabbed_slot()

func drop_main_slot():
	var slot_d = main_inv.main_slot
	var pos = -global_transform.basis.z + (global_transform * Vector3(0, 0, -3.5))
	get_parent().drop_slot.rpc(slot_d.item_data.unique_name, slot_d.stack_count, pos)
	main_inv.remove_main_slot()

func _on_sec_inv_visible():
	if !sec_inv_panel.visible: drop_active_slot()

#OTHER
func _on_lc_down():
	Input.action_press("lc")

func _on_lc_up():
	Input.action_release("lc")

func _on_rc_down():
	Input.action_press("rc")

func _on_rc_up():
	Input.action_release("rc")

func _on_chat_pressed():
	chat_layer.show()
	layer_1.hide()
	await get_tree().create_timer(0.1).timeout
	chat_layer.get_node("Panel").line_edit.grab_focus()

func receive_msg(msg: String):
	chat_layer.get_node("Panel").receive_msg(msg)

func _on_jump_pressed():
	velocity.y = JUMP_VELOCITY

func _on_chat_layer_visibility_changed():
	get_parent().chat_visible = chat_layer.visible
	chat_visib = chat_layer.visible
