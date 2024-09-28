class_name Player3D
extends CharacterBody3D

const RC_EAT = preload("res://resources/texture/hud/rc_eat.png")
const RC_EXP = preload("res://resources/texture/hud/rc_exp.png")
const RC_NORM = preload("res://resources/texture/hud/rc_norm.png")
const RC_THROW = preload("res://resources/texture/hud/rc_throw.png")
const JUMP_VELOCITY = 11
const MAX_HP = 300.0
const dont_walk = ['eat', 'attack_null', 'attack_melee']
const normal_speed = 10.0

var SPEED = 10.0
var gravity = 12
var senv: float
var deg89 = deg_to_rad(89)
var hp := MAX_HP
var old_velo := 0.0
var gravity_thres := 17
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
var calc_speed = 12.0
var is_desktop = false
var die: bool = false
var chat_visib := false
var uuid := ""
var player_name := ""
var tghud := false
var world_node: WorldLoader
var curr_anim := ""
var is_immune := false
var flying := false
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
@onready var info_lb = $Layer1/Control/InfoLb
@onready var animation: AnimationPlayer = $Animation
@onready var item_menu = $Layer1/Control/Panel2/Panel
@onready var item_menu_slot = $Layer1/Control/Panel2/Panel/SlotInterface
@onready var ray_cast: RayCast3D = $RayCast3D
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
@onready var dmg_overlay: TextureRect = $Layer1/Control/Hurt
@onready var lc_btn: TouchScreenButton = $Layer1/Control/LC
@onready var rc_btn: TouchScreenButton = $Layer1/Control/RC
@onready var ray_pivot: Node3D = $Armature/Skeleton3D/Head/ray_pivot
@onready var immune_timer: Timer = $ImmuneTimer

func _enter_tree():
	uniqid = name.to_int()
	set_multiplayer_authority(uniqid)
	#print('name: ', name, ' on: ', multiplayer.get_unique_id())

func _ready():
	onready()
	#await set_player_data()
	if multiplayer.get_unique_id() != get_multiplayer_authority(): return
	
	if OS.get_name() != "Android":
		get_node("Layer1/Control/LC").hide()
		get_node("Layer1/Control/RC").hide()
		get_node("Layer1/Control/jump").hide()
		get_node("Layer1/Control/RUN").hide()
		get_node("Layer1/Control/Panel/Hbox/Button").hide()
		get_node("Layer1/Control/VJ").hide()
		get_node("Layer1/Control/Pause").hide()
		get_node("Layer1/Control/Chat").hide()
		is_desktop = true
	get_node("Layer1/Control/PausePanel/Vbox/game_addr").text = GManager.game_addr
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
		camera.far = Settings.render_distance * Settings.CHUNK_SIZE
	update_hp()
	if is_desktop: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	chat_layer.get_node("Panel").chat_manager = world_node.get_node("ChatManager")
	await RenderingServer.frame_post_draw
	main_inv.set_main_slot(0)
	main_inv.check_main_slot()
	set_processes(true)

func set_player_data():
	var player_info = GManager.players[uniqid]
	uuid = player_info.uuid
	label_3d.text = player_info.name
	player_name = player_info.name
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.html(player_info.color)
	cube.material_overlay = mat
	world_node.receive_msg.connect(receive_msg)
	world_node.player_nodes[player_info.name] = self
	if !GManager.world_data.has('players'): return
	if !GManager.world_data.players.has(uuid): return
	var player_data = GManager.world_data.players[uuid]
	position = player_data.pos
	rotation = player_data.rot
	head.rotation = player_data.head_rot
	deserialize(player_data.extra_data)

@rpc("any_peer")
func send_data():
	if multiplayer.is_server(): return
	GManager.send_player_info.rpc_id(1, uniqid, Settings.player_uuid, Settings.player_name, Settings.player_color.to_html())

func onready():
	world_node = get_parent().get_parent()
	layer_1.hide()
	main_inv = MainInv.new(3)
	sec_inv = InvData.new(18)
	set_processes(false)

func _process(_delta):
	info_lb.text = "POS: "+str(Vector3i(position))+"\nFPS: "+str(Engine.get_frames_per_second())
	ray_cast.global_position = ray_pivot.global_position
	ray_cast.global_rotation = ray_pivot.global_rotation
	if position.y < -200:
		take_damage.rpc(999999999)

func _physics_process(delta: float):
	if Input.is_action_just_pressed("jump") and is_on_floor() and !paused and !chat_visib and !flying: velocity.y = JUMP_VELOCITY
	var input_dir = Input.get_vector("a", "d", "w", "s")
	if paused or chat_layer.visible or inv_opened: input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_SPACE) and flying: velocity.y = 20
	elif Input.is_key_pressed(KEY_SHIFT) and flying: velocity.y = -20
	if !Input.is_key_pressed(KEY_SHIFT) and !Input.is_key_pressed(KEY_SPACE) and flying: velocity.y = 0
	if !is_on_floor() and !flying: velocity.y -= gravity * delta
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if dont_walk.has(curr_anim): direction = Vector3.ZERO
	if direction:
		velocity.x = direction.x * calc_speed
		velocity.z = direction.z * calc_speed
		play_anim_local.rpc("walk")
	else:
		velocity.x = 0
		velocity.z = 0
		if !dont_walk.has(curr_anim): play_anim_local.rpc("idle")
	if head.rotation_degrees.y != 0.0 and velocity != Vector3.ZERO:
		look_front()
	move_and_slide()
	velocity = velocity
	if old_velo < 0:
		var diff = velocity.y - old_velo
		if diff > gravity_thres and !flying: take_damage(roundi(diff - gravity_thres))
	old_velo = velocity.y

func _input(event: InputEvent):
	if multiplayer.get_unique_id() != get_multiplayer_authority(): return
	if((event is InputEventMouseMotion and is_desktop) or (event is InputEventScreenDrag and !is_desktop)) and !paused and !chat_visib and !inv_opened:
		head.rotation.z = 0
		head.rotation_degrees.x += (-event.relative.y) * get_process_delta_time() * senv
		head.rotation.x = clamp(head.rotation.x, -deg89, deg89)
		head.rotation_degrees.y += (-event.relative.x) * get_process_delta_time() * senv
		if head.rotation_degrees.y  >= 80 or head.rotation_degrees.y <= -80: rotate_y(deg_to_rad(-event.relative.x))
		head.rotation.y = clamp(head.rotation.y, -deg89, deg89)
	if Input.is_action_pressed("pause") and !chat_visib and !inv_opened: _on_paused()
	if Input.is_action_pressed("open_inv") and !chat_visib and !paused: _on_open_inv()
	if chat_visib or paused or inv_opened: return
	if Input.is_action_pressed("chat"): _on_chat_pressed()
	if Input.is_action_pressed("change_view"): _change_view()
	if Input.is_action_pressed("drop_slot"): drop_main_slot()
	if Input.is_action_pressed("lc"): left_click()
	if Input.is_action_pressed("rc"): right_click()
	if Input.is_action_pressed("tg_run"): _on_run_toggled(!running)
	if Input.is_action_pressed("tg_hud"): tg_hud()
	if Input.is_key_pressed(KEY_F): flying = !flying

func _unhandled_input(_event: InputEvent):
	if chat_visib: return
	if Input.is_key_pressed(KEY_1): main_inv.set_main_slot(0)
	elif Input.is_key_pressed(KEY_2): main_inv.set_main_slot(1)
	elif Input.is_key_pressed(KEY_3): main_inv.set_main_slot(2)
	else: pass

@rpc("call_local")
func play_anim_local(anim_name):
	animation.play(anim_name)

func look_front():
	rotate_y(head.rotation.y)
	head.rotation.y = 0.0

func tg_hud():
	tghud = !tghud
	if tghud: hide_2d()
	else: show_2d()

func heal(healed_hp: int):
	hp = ceil(clamp(hp + healed_hp, 0, MAX_HP))
	update_hp()

@rpc("any_peer")
func take_damage(dmg: int):
	if is_immune: return
	hp = floor(clamp(hp - dmg, 0, MAX_HP))
	update_hp()
	hurt()
	if hp == 0: death.rpc()

func hurt():
	if !is_multiplayer_authority(): return
	dmg_overlay.modulate = Color.WHITE
	if hurt_tween: hurt_tween.kill()
	hurt_tween = create_tween()
	hurt_tween.tween_property(dmg_overlay, "modulate", Color.TRANSPARENT, 0.25)

func update_hp():
	hpbar.color = gradient_hp.sample(hp / MAX_HP)
	hpbar.scale.x = hp / MAX_HP
	hpbar_lb.text = "%s HP" % hp

@rpc("call_local")
func death():
	SPEED = normal_speed
	_on_run_toggled(running)
	layer_1.hide()
	set_processes(false)
	hide()
	if name.to_int() != multiplayer.get_unique_id(): return
	tg_mouse_visibility(true)
	death_sc.show()

#@rpc("call_local")
func immune_after_death():
	if !is_multiplayer_authority(): return
	is_immune = true
	immune_timer.start()

func _on_respawn():
	respawn.rpc()
	#immune_after_death.rpc()
	if !is_multiplayer_authority(): return
	layer_1.show()
	death_sc.hide()
	set_processes(true)
	tg_mouse_visibility(false)
	if paused: _on_paused()
	main_inv.set_main_slot(0)

@rpc("call_local")
func respawn():
	immune_after_death()
	show()
	hp = MAX_HP
	update_hp()
	position = world_node.world_spawn

func _on_back_pressed():
	if multiplayer.is_server():
		multiplayer.server_disconnected.emit()
		return
	world_node.disconnect_peer(uniqid)
	await get_tree().create_timer(0.5).timeout
	multiplayer.multiplayer_peer = null
	GManager.players.clear()
	get_tree().change_scene_to_packed(world_node.main_menu)

func _on_paused():
	paused = !paused
	if paused:
		tg_mouse_visibility(true)
		pause_panel.show()
	else:
		tg_mouse_visibility(false)
		pause_panel.hide()

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

func _on_current_animation_changed(anim_name: String):
	curr_anim = anim_name

func _on_animation_finished(_anim_name: String):
	curr_anim = ""

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

@rpc("any_peer")
func left_click():
	look_front()
	if !cooldown_finished: return
	if is_instance_valid(main_item): apply_cooldown(main_item.cooldown)
	if(main_item is MeleeItem):
		var obj = ray_cast.get_collider()
		play_anim_local.rpc("attack_melee")
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

@rpc("any_peer")
func right_click():
	look_front()
	if !cooldown_finished: return
	if(main_item is MeleeItem):
		if !main_item.throwable_melee: return
		melee_throw.play()
		world_node.throw_item.rpc(main_item.unique_name, -cams[0].global_basis.z + (cams[0].global_transform * Vector3(0, 0, -1.5)), -cams[0].global_basis.z, name.to_int())
		main_inv.remove_main_slot()
		main_inv.check_main_slot()
	elif(main_item is FoodItem):
		eat()
	elif(main_item is DrinkItem):
		drink()
	elif(main_item is ExplodableItem):
		apply_cooldown(0.5)
		grenade_throw.play()
		world_node.throw_grenade.rpc(main_item.unique_name, -cams[0].global_basis.z + (cams[0].global_transform * Vector3(0, 0, -1.5)), -cams[0].global_basis.z)
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
	world_node.launch_rocket.rpc(-cams[0].global_basis.z + (cams[0].global_transform * Vector3(0, 0, -1.5)), -cams[0].global_basis.z)
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
	await sec_inv.update()

@rpc("call_local")
func drink():
	apply_cooldown(main_item.cooldown)
	play_anim_local.rpc("eat")
	drink_effect.play()
	await get_tree().create_timer(main_item.cooldown).timeout
	get_node("SpeedTimer").start()
	var drink_i = main_inv.slot_datas[main_inv.main_slot_idx]
	drink_i.stack_count -= 1
	if drink_i.stack_count < 1: main_inv.remove_main_slot()
	await main_inv.update()
	SPEED *= 4
	_on_run_toggled(running)

func _on_speed_effect_timeout():
	SPEED = normal_speed
	_on_run_toggled(running)
@rpc("call_local")
func eat():
	apply_cooldown(main_item.cooldown)
	play_anim_local.rpc("eat")
	eat_effect.play()
	await get_tree().create_timer(main_item.cooldown).timeout
	var food = main_inv.slot_datas[main_inv.main_slot_idx]
	food.stack_count -= 1
	if food.stack_count < 1: main_inv.remove_main_slot()
	await main_inv.update()
	heal(main_item.heal)
@rpc("call_local")
func punch():
	var obj = ray_cast.get_collider()
	play_anim_local.rpc("attack_null")
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
	var items = world_node.items
	for i in 3:
		main_inv.slot_datas[i].item_data = items[dats[i].item]
		main_inv.slot_datas[i].stack_count = dats[i].stack_count
	await RenderingServer.frame_post_draw
	main_inv.set_main_slot(0)

func _on_open_inv():
	inv_opened = !inv_opened
	if inv_opened:
		tg_mouse_visibility(true)
		sec_inv_panel.show()
	else:
		tg_mouse_visibility(false)
		sec_inv_panel.hide()

func no_item():
	item_label.hide()
	for child in onhand_item.get_children(): child.queue_free()
	onhand_item.hide()

func reset_icon():
	rc_btn.texture_normal = RC_NORM

func main_slot_changed(slot_d: SlotData):
	var unique_item_name: String = '' if !is_instance_valid(slot_d.item_data) else slot_d.item_data.unique_name
	local_main_slot_change.rpc(unique_item_name)
	no_item()
	main_item = null
	reset_icon()
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
		rc_btn.texture_normal = RC_EXP
	else:
		if main_item is DrinkItem or main_item is FoodItem:
			rc_btn.texture_normal = RC_EAT
		elif main_item is ExplodableItem: rc_btn.texture_normal = RC_EXP
		elif main_item is MeleeItem and main_item.throwable_melee: rc_btn.texture_normal = RC_THROW
		else: reset_icon()
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
func local_main_slot_change(item_name: String):
	print('called on id ', multiplayer.get_unique_id())
	#var slot_d = main_inv.get_slot(idx)
	var item_dat = world_node.items[item_name]
	no_item()
	main_item = null
	if !is_instance_valid(item_dat):
		handup_down()
		hand_down()
		return
	main_item = item_dat
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

func fill_empty_slot_with_item(item, stack_count: int):
	var idx = main_inv.get_empty_slot_idx()
	if idx < 0: idx = sec_inv.get_empty_slot_idx()
	else:
		main_inv.slot_datas[idx].item_data = item
		main_inv.slot_datas[idx].stack_count = stack_count
		await RenderingServer.frame_post_draw
		main_inv.inv_updated.emit(main_inv)
		main_inv.check_main_slot()
		return
	sec_inv.slot_datas[idx].item_data = item
	sec_inv.slot_datas[idx].stack_count = stack_count
	await RenderingServer.frame_post_draw
	sec_inv.inv_updated.emit(sec_inv)

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
	world_node.drop_slot.rpc(slot_d.item_data.unique_name, slot_d.stack_count, pos)
	active_slot = null
	check_grabbed_slot()

func drop_single_active_slot():
	var slot_d = active_slot.create_single_slot()
	var pos = -global_transform.basis.z + (global_transform * Vector3(0, 0, -3.5))
	world_node.drop_slot.rpc(slot_d.item_data.unique_name, slot_d.stack_count, pos)
	if active_slot.stack_count == 0: active_slot = null
	check_grabbed_slot()

func drop_main_slot():
	var slot_d = main_inv.main_slot
	if !is_instance_valid(slot_d): return
	if !is_instance_valid(slot_d.item_data): return
	var pos = -global_transform.basis.z + (global_transform * Vector3(0, 0, -3.5))
	world_node.drop_slot.rpc(slot_d.item_data.unique_name, slot_d.stack_count, pos)
	main_inv.remove_main_slot()

func _on_sec_inv_visible():
	if !sec_inv_panel.visible: drop_active_slot()

func _drop_inv():
	pass#future code

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
	world_node.chat_visible = chat_layer.visible
	chat_visib = chat_layer.visible
	if chat_visib: tg_mouse_visibility(true)
	else: tg_mouse_visibility(false)

func hide_2d():
	layer_1.hide()
	chat_layer.hide()
	death_sc.hide()

func show_2d():
	layer_1.show()

func get_head_rotation():
	return head.rotation

func get_data():
	var data = {
		'hp': hp,
		'inv': [main_inv.serialize(), sec_inv.serialize(), main_inv.main_slot_idx]
	}
	return data

func deserialize(data: Dictionary):
	print('name: ', multiplayer.get_unique_id(), 'data: ',data.inv[0])
	var items = world_node.items
	hp = data.hp
	update_hp()
	main_inv.deserialize(data.inv[0], items)
	sec_inv.deserialize(data.inv[1], items)
	await RenderingServer.frame_post_draw
	sec_inv.inv_updated.emit(sec_inv)
	await RenderingServer.frame_post_draw
	main_inv.set_main_slot(data.inv[2])

func set_processes(enabled: bool):
	set_process(enabled)
	set_physics_process(enabled)
	set_process_input(enabled)
	set_process_unhandled_input(enabled)

func tg_mouse_visibility(showed: bool):
	if showed: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_immune_timer_timeout() -> void:
	is_immune = false
	immune_timer.stop()
