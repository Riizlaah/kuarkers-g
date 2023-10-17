extends CharacterBody3D

var SPEED = 10.0
const JUMP_VELOCITY = 6
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
var damage = 10
var cooldown := 0
#var grabbed_slotD: slotData

@onready var hpbar = $Control/HUD/hp_bar
@onready var lb_hpbar = $Control/HUD/Label
@onready var head = $Badan/Kepala
@onready var anim = $AnimationPlayer
@onready var rayc : RayCast3D = $Badan/Kepala/Camera3D/RayCast3D
@onready var dscreen = $DeathScreen
@onready var ctrl_ui = $Control
@onready var cam = $Badan/Kepala/Camera3D
@onready var inv_player = $Control/Inv_Player
@onready var sprite = $Badan/Bahu_kanan/Lengan/Siku/Lengan2/Sprite3D
@onready var lb_name = $Badan/Kepala/Name

func _ready():
	# Set ukuran awal health bar sesuai dengan nilai maxHealth
	hpbar.scale.x = (currentHealth / maxHealth) * sn
	lb_hpbar.text = str(currentHealth)
	senv = Settings.senv
	cam.fov = Settings.fov
	lb_name.text = Settings.p_name


func _physics_process(delta):
	if cooldown != 0:
		cooldown -= 1
	if currentHealth == 0:
		if cam_pos == null:
			cam_pos = cam.global_position
		anim.play("die")
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
		#SPEED = 10.0
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
		#SPEED = 10.0
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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
	anim.play("damaged")
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
#	sprite.texture = load("res://Texture/inv/transparan.png")
#	sprite.scale = Vector3(0.5,0.5,0.5)
#	sprite.position = Vector3.ZERO
#	sprite.rotation_degrees = Vector3.ZERO
	sprite.hide()
	damage = 1
	SPEED = 10
func pick_up_slot(slot_d: slotData):
	return inv_player.pick_up_slot(slot_d)
func set_properti(data: ItemType):
	SPEED = data.speed
	damage = data.damage



func _on_respawn():
	position = Vector3(0, 5, 0)
	visible = true
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
		var obj_unk = rayc.get_collider().player_interact()
		if obj_unk == null:
			pass
		elif obj_unk is invData:
			pass
	elif rayc.is_colliding() and rayc.get_collider().has_method("takeDamage"):
		rayc.get_collider().takeDamage(damage)


func _on_left_pressed():
	if cooldown == 0:
		cooldown = 60
	else:
		return
	interact_left()
	pass # Replace with function body.


func _on_hud_pressed():
	ctrl_ui.hide()
	pass # Replace with function body.



