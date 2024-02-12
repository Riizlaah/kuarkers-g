extends CharacterBody3D
class_name Player

const JUMP_VELOCITY = 8
const grn_s = preload("res://scene/inv/throw-ex.tscn")
const rocket_s = preload("res://scene/rocket.tscn")
const pickup_s = preload("res://scene/inv/pick_up.tscn")
const BASE_SPEED = 15.0

var nama_player: String
var SPEED = 15.0
var tmp_velo: Vector3 = Vector3.ZERO
var time_tmp_velo := 60
var senv = 0.25
var minHeight = 6
var startFall: Variant = null
var ground: Variant = null
var maxHealth = 100.00
var sn = 1.3
var die = false
var cam_pos: Vector3 = Vector3.ZERO
var gravity = 10
var old_velo := 0.0
@export var grav_treshold := 10
var paused = false
@export var currentHealth := 100.0
var damage = 5
var cooldown := 0
var cd_template := 60
var RoF := 1
var is_reloading := false
var is_reloading2 := false
var time_eff := 0
var effect := {}
var sec_inv: invData
var main_inv: MainInv
var ftime = 600
var tgHud: bool = false
var hurt_tween: Tween

@onready var lb_hpbar = $Control/HUD/Vbox/HP
@onready var head = $Badan/Kepala
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var rayc : RayCast3D = $Badan/Kepala/Camera3D/MeleeRay
@onready var dscreen = $CanvasLayer
@onready var ctrl_ui = $Control
@onready var cam: Camera3D = $Badan/Kepala/Camera3D
@onready var inv_player = $Control/Inv_Player
@onready var sprite = $Badan/Bahu_kanan/Lengan/Siku/Lengan2/Sprite3D
@onready var lb_name = $Badan/Kepala/Name
@onready var joystick_l: VirtualJoystick = $Control/Joystick
@onready var world_node = $"/root/World"
@onready var ammo_lb = $Control/HUD/Vbox/Ammo
@onready var weapon_ray = $Badan/Kepala/Camera3D/WeaponRay
@onready var bahu_kanan = $Badan/Bahu_kanan
@onready var dmg_overlay = $Control/DmgOverlay

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	if multiplayer.get_unique_id() != get_multiplayer_authority(): return
	$Control/Joystick.scale = Vector2(Settings.s_joystick, Settings.s_joystick)
	await get_tree().create_timer(0.1).timeout
	ctrl_ui.show()
	ctrl_ui.set_multiplayer_authority(name.to_int())
	await get_tree().create_timer(0.2).timeout
	cam.current = true
	senv = Settings.senv
	main_inv = inv_player.main_inv
	sec_inv = inv_player.sec_inv
	cam.far = Settings.r_dist
	update_health_bar.rpc()

func _physics_process(delta):
	if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	if cooldown > 0:
		cooldown -= 1
	if time_eff > 0:
		time_eff -= 1
	elif time_eff == 0:
		reset_effect()
	else:
		pass
	if ftime == 0:
		_dying()
		ftime = -1
	if is_on_car: return
	if is_on_floor() and Input.is_action_pressed("jump"): velocity.y = JUMP_VELOCITY
	elif !is_on_floor(): velocity.y -= gravity * delta
	var input_dir = Input.get_vector("a","d","w","s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if time_tmp_velo == 0:
		time_tmp_velo = 60
		tmp_velo = Vector3.ZERO
	if time_tmp_velo > 0:
		if tmp_velo.length() > 0.0: velocity = tmp_velo
		time_tmp_velo -= 1
	move_and_slide()
	velocity = velocity
	if old_velo < 0:
		var diff = velocity.y - old_velo
		if diff > grav_treshold:
			takeDamage.rpc(diff - grav_treshold)
	old_velo = velocity.y
	match anim.current_animation:
		"shoot", "attack", "scope":
			pass
		_:
			if is_on_floor() and velocity.length() > 0.5:
				if _is_forward() == true: anim.play("move")
				else: anim.play_backwards("move")
			if velocity.length() == 0: 
				anim.play("idle")
			if inv_player.toggle_s == true: bahu_kanan.rotation.y = deg_to_rad(20)
			if is_holding_gun: bahu_kanan.rotation_degrees.x = 90
			else: bahu_kanan.rotation.x = 0
	if head.rotation_degrees.y != 0 and velocity != Vector3.ZERO:
		rotate_y(head.rotation.y)
		head.rotation.y = 0

func _input(event):
	if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	if event is InputEventScreenDrag and die == false and paused == false:
		head.rotate_y(deg_to_rad(-event.relative.x * senv))
		head.rotation.y = clamp(head.rotation.y, deg_to_rad(-81), deg_to_rad(81))
		if head.rotation_degrees.y >= 70 or head.rotation_degrees.y <= -70:
			rotate_y(deg_to_rad(-event.relative.x))
		cam.rotate_x(deg_to_rad(-event.relative.y * senv))
		cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-60), deg_to_rad(89))
	if event.is_action_pressed("tg_hud"):
		tgHud = !tgHud
		ctrl_ui.visible = tgHud
	if Input.is_action_pressed("left_click"):
		on_left_pressed()

func _is_forward() -> bool:
	var f_dir = transform.basis.z
	return velocity.dot(f_dir) > 0

func _dying(arg1 = false, arg2 = false):
	if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	death.rpc(arg1, arg2)
	await get_tree().create_timer(0.1).timeout
	ctrl_ui.hide()
	dscreen.show()
	hide()
	global_position.y = -100
	set_collision_layer_value(2, false)
	set_collision_layer_value(3, false)
	set_physics_process(false)
	currentHealth = -1
	die = true

@rpc("any_peer", "call_local", "reliable")
func takeDamage(dmg, sync: bool = false):
	if sync == false:
		if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	if multiplayer.get_remote_sender_id() == 0 or sync == true: takeDamage.rpc(dmg)
	currentHealth = floor(clamp(currentHealth - dmg, 0, maxHealth))
	cam.rotation_degrees.z = -5
	await get_tree().create_timer(0.1).timeout
	cam.rotation_degrees.z = 0
	update_health_bar.rpc()
	hurt()
	if currentHealth == 0:
		_dying()
func hurt():
	if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	dmg_overlay.modulate = Color.WHITE
	if hurt_tween: hurt_tween.kill()
	hurt_tween = create_tween()
	hurt_tween.tween_property(dmg_overlay, "modulate", Color.TRANSPARENT, 0.25)
@rpc("any_peer", "call_local", "reliable")
func heal(healing):
	if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	if multiplayer.get_remote_sender_id() == 0: heal.rpc(healing)
	currentHealth = ceil(clamp(currentHealth + healing, 0, maxHealth))
	update_health_bar.rpc()

# Fungsi untuk memperbarui tampilan health bar
@rpc("any_peer", "call_local")#FIXME: hp tidak terupdate
func update_health_bar():
	lb_hpbar.text = "HP: " + str(currentHealth)
	lb_name.text = nama_player + " : " + str(currentHealth)
#Inv
@rpc("any_peer", "call_local", "reliable")
func set_onhand_item(slot):
	if get_multiplayer_authority() != multiplayer.get_unique_id() \
	or multiplayer.get_remote_sender_id() != get_multiplayer_authority(): return
	sprite.show()
	var data 
	if slot is EncodedObjectAsID:
		data = instance_from_id(slot.object_id)
		data = data.item_data
	else:
		data = slot.item_data
	sprite.texture = data.onhand_texture
	sprite.scale = Vector3(data.onhand_scale, data.onhand_scale, data.onhand_scale)
	sprite.position = data.onhand_pos
	sprite.rotation_degrees = data.onhand_rot
@rpc("any_peer", "call_local")
func reset_onhand_item():
	if get_multiplayer_authority() != multiplayer.get_unique_id() \
	or multiplayer.get_remote_sender_id() != get_multiplayer_authority(): return
	sprite.hide()
	damage = 1
	SPEED = BASE_SPEED
	is_holding_gun = false
	if !effect.is_empty() and time_eff > 0:
		eff()
func pick_up_slot(slot_d: slotData):
	return inv_player.pick_up_slot(slot_d)
func set_properti(data: ItemType):
	if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	damage = data.damage
	cd_template = data.cooldown
	if !effect.is_empty() and time_eff > 0:
		eff()

@rpc("any_peer", "call_local", "reliable")
func death(free_obj : bool = false, free_item: bool = false):
	if get_multiplayer_authority() != multiplayer.get_unique_id() \
	or multiplayer.get_remote_sender_id() != get_multiplayer_authority(): return
	if free_item == false:
		for slot in main_inv.slotDatas:
			if slot.item_data != null:
				var pickup = pickup_s.instantiate()
				pickup.slot_d = slot
				pickup.slot_d.active = false
				pickup.position = cam.global_position
				world_node.add_child(pickup)
		for slot in sec_inv.slotDatas:
			if slot.item_data != null:
				var pickup = pickup_s.instantiate()
				pickup.slot_d = slot
				pickup.slot_d.active = false
				pickup.position = cam.global_position
				world_node.add_child(pickup)
	inv_player.clear_slot()
	reset_onhand_item()
	if free_obj == true:
		queue_free()

func _on_respawn():
	_respawn.rpc()
@rpc("call_local", "unreliable_ordered")
func _respawn():
	if is_on_car:
		car.exit_car(name)
	die = false
	ftime = 300
	global_position = Vector3(0, 5, 0)
	show()
	anim.play("RESET")
	rotation.x = 0
	currentHealth = maxHealth
	update_health_bar.rpc()
	dscreen.hide()
	ctrl_ui.show()
	setRandomWeapon()
	cam_pos = Vector3.ZERO
	cam.position = Vector3(0, 0.1, 0.1)
	set_collision_layer_value(2, true)
	set_collision_layer_value(3, true)
	set_physics_process(true)

func _anim_scope(animate: bool):
	if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	if animate: anim.play("scope")
	else: anim.play_backwards("scope")
func pause():
	paused = !paused
@rpc("call_local")
func interact_left():
	anim.play("attack")
	if !rayc.is_colliding():
		return
	var collider = rayc.get_collider()
	if collider is Musuh1:
		collider.takeDamage(damage)
		return
	collider.takeDamage.rpc_id(collider.name.to_int(), damage)

var is_holding_gun: bool = true
func on_left_pressed():
	if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	if cooldown == 0:
		cooldown = cd_template
		if inv_player.mainItem == null: return
		if inv_player.mainItem.type is GunType:
			RoF = inv_player.mainItem.type.rate_of_fire
	else:
		return
	if inv_player.mainItem.type is GunType:
		shoot_bullet()
	elif inv_player.mainItem.type is ThrowExType:
		throw_grenade.rpc()
	elif inv_player.mainItem.type is RPGType:
		shoot_rocket.rpc()
	else:
		interact_left.rpc()
@rpc("call_local")
func shoot_rocket():
	if not Input.is_action_pressed("left_click"):
		return
	if is_reloading2 == true:
		return
	#cek peluru
	inv_player.mainItem.type.c_ammo -= 1
	if inv_player.mainItem.type.c_ammo < 0:
		reload_rocket()
		await get_tree().create_timer(2).timeout
		is_reloading2 = false
		return
	anim.play("shoot")
	#tembak
	update_ammo()
	cooldown = 120
	var rocket = rocket_s.instantiate()
	rocket.position = cam.global_position + (cam.global_transform.basis * Vector3(0,0,-1.5))
	world_node.add_child(rocket)
	rocket.launch(-global_transform.basis.z * 2)#FIXME: ROKETE ILANG
	#update
@rpc("call_local")
func throw_grenade():
	var grenade = inv_player.main_inv.find_name("Granat")
	if grenade == null:
		return
	var throw_i = grn_s.instantiate()
	throw_i.position = -cam.global_transform.basis.z + (cam.global_transform * Vector3(0,0,-1))
	world_node.add_child(throw_i)
	throw_i.throw(-cam.global_transform.basis.z)
	grenade.quantity -= 1
	if grenade.quantity < 0:
		grenade = slotData.new()
	grenade.active = true
	inv_player.main_inv.set_s_index(grenade)

func update_ammo():
	ammo_lb.show()
	ammo_lb.text = "Ammo: " + str(inv_player.mainItem.type.c_ammo) + "/" + str(inv_player.mainItem.type.max_ammo)
	pass
func reload_rocket():
	is_reloading2 = true
	var ammo = inv_player.main_inv.find_name("Roket")
	if ammo == null:
		ammo = inv_player.sec_inv.find_name("Roket")
	if ammo == null:
		return
	ammo.quantity -= 7
	if ammo.quantity < 0:
		ammo = slotData.new()
	await get_tree().create_timer(2).timeout
	inv_player.mainItem.type.c_ammo = inv_player.mainItem.type.max_ammo
	update_ammo()
	inv_player.main_inv.set_s_index(ammo)
	inv_player.sec_inv.set_s_index(ammo)
func reload():
	is_reloading = true
	#cari item peluru
	var ammo = inv_player.search_ammo()
	if ammo == null:
		return
	
	#reload
	ammo.quantity -= 1
	if ammo.quantity < 0:
		ammo = slotData.new()
		inv_player.update_ammo(ammo)
		return
	await get_tree().create_timer(inv_player.mainItem.type.reload_time / 60).timeout
	inv_player.mainItem.type.c_ammo = inv_player.mainItem.type.max_ammo
	update_ammo()
	inv_player.update_ammo()
func shoot_bullet():
	if Input.is_action_pressed("left_click") == false:
		return
	if is_reloading == true:
		return
	inv_player.mainItem.type.c_ammo -= 1
	if inv_player.mainItem.type.c_ammo < 0:
		reload()
		await get_tree().create_timer(1).timeout
		is_reloading = false
		return
	_anim_shoot.rpc()
	update_ammo()
	if inv_player.mainItem.type.rate_of_fire > 1:
		await get_tree().create_timer(1.0 / inv_player.mainItem.type.rate_of_fire).timeout
	if weapon_ray.is_colliding():
		var collider = weapon_ray.get_collider()
		if collider is Musuh1:
			collider.takeDamage(inv_player.mainItem.type.bullet_damage)
			return
		collider.takeDamage.rpc_id(collider.name.to_int(), inv_player.mainItem.type.bullet_damage)
	RoF -= 1
	if RoF == 0:
		return
	shoot_bullet()
@rpc("call_local", "unreliable_ordered")
func _anim_shoot():
	anim.stop()
	anim.play("shoot")

func take_effect(spd: float, dmg: int, time: int):
	effect["speed"] = spd * 2
	effect["damage"] = dmg
	time_eff = time
	eff()
func eff():
	SPEED += effect["speed"]
	damage += effect["damage"]
func reset_effect():
	SPEED = BASE_SPEED
	damage = 5
	time_eff = -1
	effect.clear()

func setRandomItem():
	var RandItemArr = []
	var ResItemArr : Array = world_node.ResItemArr
	for i in range(7):
		RandItemArr.append(ResItemArr.pick_random())
	for i in range(3):
		inv_player.main_inv.slotDatas[i].item_data = RandItemArr[i]
		inv_player.main_inv.slotDatas[i].quantity = randi_range(1, 21)
	RandItemArr = RandItemArr.slice(3)
	for i in range(4):
		inv_player.sec_inv.slotDatas[i].item_data = RandItemArr[i]
		inv_player.sec_inv.slotDatas[i].quantity = randi_range(1, 21)
	inv_player.update_ammo()
	await get_tree().create_timer(0.02).timeout
	inv_player.set_main_s()
	inv_player.check_gun()

#ketika respawn
func setRandomWeapon():
	var RandItem: Array = world_node.WpItemArr
	inv_player.main_inv.slotDatas[0].item_data = RandItem.pick_random()
	inv_player.main_inv.slotDatas[0].quantity = randi_range(1, 15)
	inv_player.update_ammo()
	inv_player.set_main_s()

@rpc("any_peer", "call_local")
func launch(id, dir, power: int = 35):
	if id != name: return
	tmp_velo = dir * power

#CAR MECHANIC
var car
var supir: bool
var is_on_car: bool = false
@rpc("any_peer", "reliable")
func req_car_join(car1: String, what: int):
	car = world_node.get_node(car1)
	if what == 0:
		supir = true
	else:
		supir = false
	ctrl_ui.toggle_car_ui(what)
@rpc("any_peer", "unreliable_ordered")
func clear_req():
	car = null
	ctrl_ui.toggle_car_ui(1, true)
func _on_join_car_toggled(toggled_on: bool):
	if !toggled_on:
		car.exit_car.rpc(name)
		ctrl_ui.toggle_oncar_ui(true)
		return
	car.join_car.rpc(name, supir)
	is_on_car = true
@rpc("any_peer", "reliable")
func toggle_exit(car1: String):
	car = world_node.get_node(car1)
	ctrl_ui.toggle_car_ui(2)
@rpc("any_peer", "reliable")
func exit_from_car():
	set_collision_layer_value(2, true)
	set_collision_layer_value(3, true)
	is_on_car = false
	clear_req()
	rotation.x = 0
	rotation.z = 0

