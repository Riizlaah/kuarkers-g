extends CharacterBody3D
class_name Player

const JUMP_VELOCITY = 6
const bullet_s = preload("res://scene/bullet.tscn")
const grn_s = preload("res://scene/inv/throw-ex.tscn")
const rocket_s = preload("res://scene/rocket.tscn")
const pickup_s = preload("res://scene/inv/pick_up.tscn")

var SPEED = 10.0
var senv = 0.25
var min_h = 5.5
var fall_h = 0.00
var s_fall = 0
var ground = null
var maxHealth = 100.00
var sn = 1.3
var die = false
var cam_pos: Vector3 = Vector3.ZERO
var gravity = 10
var paused = false
var currentHealth = 100.00
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
var ftime = 300
var tgHud: bool = false

@onready var hpbar = $Control/HUD/hp_bar
@onready var lb_hpbar = $Control/HUD/Label
@onready var head = $Badan/Kepala
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var rayc : RayCast3D = $Badan/Kepala/Camera3D/RayCast3D
@onready var dscreen = $CanvasLayer
@onready var ctrl_ui = $Control
@onready var cam: Camera3D = $Badan/Kepala/Camera3D
@onready var inv_player = $Control/Inv_Player
@onready var sprite = $Badan/Bahu_kanan/Lengan/Siku/Lengan2/Sprite3D
@onready var lb_name = $Badan/Kepala/Name
@onready var joystick_l: VirtualJoystick = $Control/Joystick
@onready var world_node = get_tree().root.get_node("/root/World")
@onready var ammo_lb = $Control/HUD/Ammo

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	if multiplayer.get_unique_id() != get_multiplayer_authority():
		return
	await get_tree().create_timer(0.2).timeout
	cam.current = true
	hpbar.scale.x = (currentHealth / maxHealth) * sn
	lb_hpbar.text = str(currentHealth)
	senv = Settings.senv
	cam.fov = Settings.fov
	main_inv = inv_player.main_inv
	sec_inv = inv_player.sec_inv

func _physics_process(delta):
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		return
	if cooldown != 0:
		cooldown -= 1
	if Input.is_action_pressed("left_click"):
		on_left_pressed()
	if time_eff > 0:
		time_eff -= 1
	elif time_eff == 0:
		reset_effect()
	else:
		pass
	if currentHealth == 0 and die == false:
		if cam_pos == Vector3.ZERO:
			cam_pos = cam.global_position
		anim.play("death")
		dscreen.show()
		ctrl_ui.hide()
		hide()
		set_collision_layer_value(2, false)
		set_collision_layer_value(3, false)
		currentHealth = -1
		position.y = -33
		cam.global_position = cam_pos
		die = true
		death()
	if is_on_floor() and Input.is_action_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	if !is_on_floor() and die == false:
		if s_fall == 0:
			s_fall = floor(position.y)
		velocity.y -= gravity * delta
		ftime -= 1
	elif !is_on_floor() and die == true:
		velocity.y = 0
	else:
		if ground == null:
			ground = position.y
		if s_fall - ground > min_h:
			takeDamage(s_fall - ground)
		s_fall = 0
		ground = null
		ftime = 300
	if ftime == 0:
		ctrl_ui.visible = false
		dscreen.show()
		hide()
		set_collision_layer_value(2, false)
		set_collision_layer_value(3, false)
		currentHealth = -1
		die = true
		death(false, true)
		ftime = -1
	var input_dir = Input.get_vector("a","d","w","s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if input_dir != Vector2.ZERO and is_on_floor():
		anim.play("move")
	elif anim.is_playing() and anim.current_animation != 'move':
		pass
	else:
		anim.play("idle")
	if head.rotation_degrees.y != 0 and velocity != Vector3.ZERO:
		rotate_y(head.rotation.y)
		head.rotation.y = 0
	move_and_slide()

func _input(event):
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		return
	if event is InputEventScreenDrag and die == false and paused == false:
		head.rotate_y(deg_to_rad(-event.relative.x * senv))
		head.rotation.y = clamp(head.rotation.y, deg_to_rad(-81), deg_to_rad(81))
		if head.rotation_degrees.y >= 70 or head.rotation_degrees.y <= -70:
			rotate_y(deg_to_rad(-event.relative.x))
		cam.rotate_x(deg_to_rad(-event.relative.y * senv))
		cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-60), deg_to_rad(89))

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("tg_hud"):
		tgHud = !tgHud
		ctrl_ui.visible = tgHud

@rpc("any_peer")
func takeDamage(dmg):
	currentHealth = floor(clamp(currentHealth - dmg, 0, maxHealth))
	cam.rotation_degrees.z = -5
	await get_tree().create_timer(0.1).timeout
	cam.rotation_degrees.z = 0
	update_health_bar()
# Fungsi untuk meningkatkan health
func heal(healing):
	currentHealth = ceil(clamp(currentHealth + healing, 0, maxHealth))
	update_health_bar()

# Fungsi untuk memperbarui tampilan health bar
func update_health_bar():
	hpbar.scale.x = (currentHealth / maxHealth) * sn
	lb_hpbar.text = str(currentHealth)
#Inv
func set_onhand_item(slot: slotData):
	sprite.show()
	var data = slot.item_data
	sprite.texture = data.onhand_texture
	sprite.scale = Vector3(data.onhand_scale, data.onhand_scale, data.onhand_scale)
	sprite.position = data.onhand_pos
	sprite.rotation_degrees = data.onhand_rot
func reset_onhand_item():
	sprite.hide()
	damage = 1
	SPEED = 10
	if !effect.is_empty() and time_eff > 0:
		eff()
func pick_up_slot(slot_d: slotData):
	return inv_player.pick_up_slot(slot_d)
func set_properti(data: ItemType):
	damage = data.damage
	cd_template = data.cooldown
	if !effect.is_empty() and time_eff > 0:
		eff()

func death(free_obj : bool = false, free_item: bool = false):
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
	ftime = 300
	position = Vector3(0, 5, 0)
	show()
	anim.play("RESET")
	rotation.x = 0
	currentHealth = maxHealth
	update_health_bar()
	dscreen.hide()
	ctrl_ui.show()
	setRandomWeapon()
	die = false
	cam_pos = Vector3.ZERO
	cam.position = Vector3(0, 0.1, 0.1)
	set_collision_layer_value(2, true)
	set_collision_layer_value(3, true)

func pause():
	paused = !paused

func interact_left():
	anim.play("attack")
	if !rayc.is_colliding():
		return
	var collider = rayc.get_collider()
	if collider.has_method("takeDamage"):
		collider.takeDamage.rpc_id(collider.name.to_int(),damage)


func on_left_pressed():
	if cooldown == 0:
		cooldown = cd_template
		if inv_player.mainItem.type is GunType:
			RoF = inv_player.mainItem.type.rate_of_fire
	else:
		return
	if inv_player.mainItem.type is GunType:
		shoot_bullet()
	elif inv_player.mainItem.type is ThrowExType:
		throw_grenade()
	elif inv_player.mainItem.type is RPGType:
		shoot_rocket()
	else:
		interact_left()

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
	#tembak
	update_ammo()
	cooldown = 120
	var rocket = rocket_s.instantiate()
	rocket.position = -cam.global_transform.basis.z + (cam.global_transform * Vector3(0,0,-1))
	world_node.add_child(rocket)
	rocket.launch(-cam.global_transform.basis.z)
	#update
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
	ammo_lb.text = str(inv_player.mainItem.type.c_ammo) + "/" + str(inv_player.mainItem.type.max_ammo)
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
	#inv_player.main_inv.inv_updated.emit(inv_player.main_inv)
	#inv_player.sec_inv.inv_updated.emit(inv_player.sec_inv)
	pass

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
	update_ammo()
	if inv_player.mainItem.type.rate_of_fire > 1:
		await get_tree().create_timer(1.0 / inv_player.mainItem.type.rate_of_fire).timeout
	var bullet = bullet_s.instantiate()
	bullet.position = -cam.global_transform.basis.z + (cam.global_transform * Vector3(0,0,-1))
	bullet.damage_bullet = inv_player.mainItem.type.bullet_damage
	world_node.add_child(bullet)
	bullet.throw(-cam.global_transform.basis.z)
	RoF -= 1
	if RoF == 0:
		return
	shoot_bullet()
	pass

func take_effect(spd: float, dmg: int, time: int):
	effect["speed"] = spd
	effect["damage"] = dmg
	time_eff = time
	eff()
func eff():
	SPEED += effect["speed"]
	damage += effect["damage"]
func reset_effect():
	SPEED = 10.0
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

#ketika respawn
func setRandomWeapon():
	var RandItem: Array = world_node.WpItemArr
	main_inv.slotDatas[0].item_data = RandItem.pick_random()
	main_inv.slotDatas[0].quantity = randi_range(1, 15)
	inv_player.update_ammo()
	inv_player.set_main_s()
