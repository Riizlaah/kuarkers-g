extends CharacterBody3D
class_name Player

const JUMP_VELOCITY = 6
const bullet_s = preload("res://scene/bullet.tscn")
const grn_s = preload("res://scene/inv/throw-ex.tscn")
const rocket_s = preload("res://scene/rocket.tscn")

var SPEED = 10.0
var senv = 0.25
var min_h = 5.5
var fall_h = 0.00
var s_fall = 0
var ground = null
var maxHealth = 100.00
var sn = 1.3
var die = false
var cam_pos = null
var gravity = 10
var paused = false
var currentHealth = 100.00
var damage = 5
var cooldown := 0.0
var cd_template := 60
var RoF := 1
var is_reloading := false
var is_reloading2 := false
var time_eff := 0
#var gun_property: GunType


@onready var hpbar = $Control/HUD/hp_bar
@onready var lb_hpbar = $Control/HUD/Label
@onready var head = $Badan/Kepala
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var rayc : RayCast3D = $Badan/Kepala/Camera3D/RayCast3D
@onready var dscreen = $DeathScreen
@onready var ctrl_ui = $Control
@onready var cam = $Badan/Kepala/Camera3D
@onready var inv_player = $Control/Inv_Player
@onready var sprite = $Badan/Bahu_kanan/Lengan/Siku/Lengan2/Sprite3D
@onready var lb_name = $Badan/Kepala/Name
@onready var joystick_l: VirtualJoystick = $Control/Joystick
@onready var world_node = get_tree().get_root().get_node("/root/World")
@onready var ammo_lb = $Control/HUD/Ammo
@onready var chat = $Control/Chat
@onready var chat_btn = $"Control/Chat-Btn"

func _ready():
	# Set ukuran awal health bar sesuai dengan nilai maxHealth
	hpbar.scale.x = (currentHealth / maxHealth) * sn
	lb_hpbar.text = str(currentHealth)
	senv = Settings.senv
	cam.fov = Settings.fov
	lb_name.text = Settings.p_name

func _physics_process(delta):
	if Input.is_action_pressed("left_click"):
		on_left_pressed()
	if cooldown != 0:
		cooldown -= 1
	if time_eff != 0 and time_eff > 0:
		time_eff -= 1
		#print(damage, SPEED, time_eff)
	if time_eff == 0:
		reset_effect()
	if currentHealth == 0:
		if cam_pos == null:
			cam_pos = cam.global_position
		anim.play("death")
		dscreen.visible = true
		ctrl_ui.visible = false
		visible = false
		currentHealth = -1
		die = true
		position.y = -33
	if die == true:
		if cam.global_position != cam_pos:
			cam.global_position = cam_pos
		cam.fov -= 0.025
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if is_on_floor() and Input.is_action_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	if !is_on_floor() and die == false:
		if s_fall == 0:
			s_fall = floor(position.y)
		velocity.y -= gravity * delta
	elif !is_on_floor() and die == true:
		velocity.y = 0
		pass
	else:
		if ground == null:
			ground = position.y
		if s_fall - ground > min_h:
			takeDamage(s_fall - ground)
		s_fall = 0
		ground = null
	var input_dir = joystick_l.output
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
	if event is InputEventScreenDrag and die == false and paused == false:
		head.rotate_y(deg_to_rad(-event.relative.x * senv))
		head.rotation.y = clamp(head.rotation.y, deg_to_rad(-81), deg_to_rad(81))
		if head.rotation_degrees.y >= 70 or head.rotation_degrees.y <= -70:
			rotate_y(deg_to_rad(-event.relative.x))
			
		#if head.rotation.y >= 80 or head.rotation.y == deg_to_rad(-89):
		cam.rotate_x(deg_to_rad(-event.relative.y * senv))
		cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-60), deg_to_rad(89))

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
func pick_up_slot(slot_d: slotData):
	return inv_player.pick_up_slot(slot_d)
func set_properti(data: ItemType):
	damage = 5
	#SPEED = data.speed
	damage += data.damage
	cd_template = data.cooldown


func _on_respawn():
	position = Vector3(0, 5, 0)
	visible = true
	anim.play("RESET")
	rotation.x = 0
	currentHealth = 100
	update_health_bar()
	dscreen.visible = false
	ctrl_ui.visible = true
	die = false
	cam.position = Vector3(0, 0.1, 0.1)

func pause():
	paused = !paused

func interact_left():
	anim.play("attack")
	if rayc.is_colliding() and rayc.get_collider().has_method("player_interact"):
#		var obj_unk = rayc.get_collider().player_interact()
#		if obj_unk == null:
#			pass
#		elif obj_unk is invData:
		pass
	elif rayc.is_colliding() and rayc.get_collider().has_method("takeDamage"):
		rayc.get_collider().takeDamage(damage)

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
		#print('yes')
		interact_left()

func _on_hud_pressed():
	ctrl_ui.hide()
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
	#print('yes')
	var ammo = inv_player.search_ammo()
	#print(ammo)
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
	SPEED += spd
	damage += dmg
	time_eff = time
	print(time_eff)
func reset_effect():
	SPEED = 10.0
	damage = 5
	time_eff = -1

func _on_chat_btn_pressed():
	chat_btn.hide()
	chat.show()
