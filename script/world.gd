extends Node3D
class_name WorldBase

signal receive_msg(msg: String)

const times = [0.23, 0.48, 0.725, 0.78, 0.98]
const throw_i = preload("res://scene/throwable_melee.tscn")
const explodable = preload("res://scene/explodable_item.tscn")
const rocket_s = preload("res://scene/rocket.tscn")

@onready var sun = $SUN
@onready var moon = $MOON
@onready var w_env : WorldEnvironment = $W_ENV
@onready var label = $CanvasLayer/Control/Label
@onready var resource_preloader = $ResourcePreloader
@onready var vbox = $CanvasLayer/Control/Panel/SCont/Vbox
@onready var panel = $CanvasLayer/Control/Panel
@onready var output_tm = $output_tm
@onready var s_cont = $CanvasLayer/Control/Panel/SCont

var noise = preload("res://resources/other/Noise1.tres")
var main_menu = preload("res://scene/main_menu.tscn")
var items: Dictionary = {'null': null}
var time : float
var time_rate : float
var noise_offset := 0.05
var items_arr: Array
var world: Node3D
var quests_started : Dictionary
var players_node: Dictionary
var chat_visible := false

@export_category("Other")
@export var player_s : PackedScene
@export var musuh: PackedScene
@export var w_npc: PackedScene
@export var pickable_sc: PackedScene
@export var output_lb: PackedScene

@export_category("Sky")
@export var sky_grad: Gradient
@export var sky_mat: ProceduralSkyMaterial
@export var day_length = 800.0
@export var s_time = 0.3
@export var sun_c : Gradient
@export var sun_ins : Curve
@export var moon_c : Gradient
@export var moon_ins : Curve
@export var sky_top_c : Gradient
@export var sky_horizon_c : Gradient
@export var sky_texture: NoiseTexture2D

func _ready():
	for res in resource_preloader.get_resource_list():
		var item: ItemData = resource_preloader.get_resource(res)
		items[res] = item
	for item in items.values():
		items_arr.append(item)
	add_child(GManager.curr_world.instantiate())
	var chat_manager = ChatManager.new()
	chat_manager.name = "ChatManager"
	add_child(chat_manager)
	chat_manager.world_node = self
	world = get_node("world")
	time_rate = 1.0 / day_length
	time = s_time
	if Settings.sky_graphic == Settings.SkyGraphics.Low:
		w_env.environment.background_mode = Environment.BG_COLOR
	else:
		if Settings.sky_graphic == Settings.SkyGraphics.High:
			sky_mat.sky_cover = sky_texture
		w_env.environment.sky = Sky.new()
		w_env.environment.sky.sky_material = sky_mat
	get_viewport().scaling_3d_scale = Settings.scale_3d
	for i in 3:
		items_arr.shuffle()
	for i in GManager.players:
		var c_player = player_s.instantiate()
		c_player.name = str(i)
		c_player.color = Color.html(GManager.players[i].color)
		c_player.player_name = GManager.players[i].name
		c_player.inv_set.connect(inv_set)
		receive_msg.connect(c_player.receive_msg)
		add_child(c_player)
		players_node[GManager.players[i].name] = c_player
	multiplayer.server_disconnected.connect(server_disconnected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	receive_msg.connect(receiving_msg)

func inv_set(player):
	player.set_inv_data(items_arr)

func _process(delta):
	time += time_rate * delta
	if time > 1.0:
		time = 0.0
	if Settings.sky_graphic == Settings.SkyGraphics.Low:
		w_env.environment.set_bg_color(sky_horizon_c.sample(time))
	else:
		process_sky(delta)
	label.text = "FPS: " + str(Engine.get_frames_per_second())

func process_sky(delta: float):
	if Settings.sky_graphic == Settings.SkyGraphics.High:
		noise_offset += delta * time_rate * 10
		noise.set("offset", Vector3(noise_offset, 0, 0))
	#sun
	sun.rotation_degrees.x = time * 360 + 90
	sun.light_color = sun_c.sample(time)
	sun.light_energy = sun_ins.sample(time)
	#moon
	moon.rotation_degrees.x = time * 360 + 270
	moon.light_color = moon_c.sample(time)
	moon.light_energy = moon_ins.sample(time)
	#Visibility sun and moon
	sun.visible = sun.light_energy > 0
	moon.visible = moon.light_energy > 0
	#Environment
	sky_mat.set("sky_top_color", sky_top_c.sample(time))
	sky_mat.set("sky_horizon_color", sky_horizon_c.sample(time))
	sky_mat.set("ground_bottom_color", sky_top_c.sample(time))
	sky_mat.set("ground_horizon_color", sky_horizon_c.sample(time))

@rpc("any_peer")
func disconnect_player(id: int):
	multiplayer.multiplayer_peer.disconnect_peer(id)

func peer_disconnected(id: int):
	players_node.erase(GManager.players[id].name)
	GManager.players.erase(id)
	get_node(str(id)).queue_free()

func server_disconnected():
	GManager.players.clear()
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_packed(main_menu)

@rpc("call_local")
func spawn_musuh(glob_pos):
	var musuh2 = musuh.instantiate()
	add_child(musuh2)
	musuh2.position = glob_pos
@rpc("call_local")
func spawn_npc1(glob_pos):
	var npc2 = w_npc.instantiate()
	npc2.position = glob_pos
	add_child(npc2)
@rpc("call_local")
func _change_time(idx):
	time = times[idx]

@rpc("any_peer", "call_local", "reliable")
func drop_slot(item_name, stack_count, glob_pos):
	var slot_d = SlotData.new()
	slot_d.item_data = items[item_name]
	slot_d.stack_count = stack_count
	var pickable = pickable_sc.instantiate()
	pickable.slot_d = slot_d
	pickable.position = glob_pos
	add_child(pickable)

@rpc("any_peer", "call_local", "reliable")
func throw_item(item_name, glob_pos, dir, from):
	var throw = throw_i.instantiate()
	throw.it_data = items[item_name]
	throw.mult_id = from
	throw.position = glob_pos
	add_child(throw)
	throw.throw(dir)

@rpc("any_peer", "call_local", "reliable")
func throw_grenade(item_name, glob_pos, dir):
	var grd_i = items[item_name]
	var grd = explodable.instantiate()
	grd.ex_range = grd_i.range_scale
	grd.damage = grd_i.damage
	grd.mesh = grd_i.mesh3d
	grd.position = glob_pos
	add_child(grd)
	grd.throw(dir, grd_i.countdown)

@rpc("any_peer", "call_local", "reliable")
func launch_rocket(glob_pos, dir):
	var rocket = rocket_s.instantiate()
	rocket.position = glob_pos
	add_child(rocket)
	rocket.launch(dir)

@rpc("any_peer", "call_local", "reliable")
func sync_npc_hp(npc_name, hp):
	world.get_node(npc_name).hp = hp

@rpc("any_peer", "call_local", "reliable")
func sync_npc_target(npc_name, target_name):
	world.get_node(npc_name).target_node = get_node(target_name)

func sync_npc_dialogues(npc_name, dialogues):
	world.get_node(npc_name).dialogues = dialogues

func run_quest(player_name, quest):
	get_node(player_name).dont_move()
	add_quest(quest, player_name)
	#add quest system

func add_quest(data, player_name):
	if quests_started.has(player_name):
		quests_started[player_name].append(data)
		return
	quests_started[player_name] = [data]

@rpc("call_local")
func send_msg(msg):
	receive_msg.emit(msg)

func receiving_msg(msg):
	if chat_visible == true: return
	panel.show()
	var lb = output_lb.instantiate()
	lb.text = msg
	vbox.add_child(lb)
	await RenderingServer.frame_post_draw
	s_cont.scroll_vertical = max(0, s_cont.get_v_scroll_bar().max_value)
	output_tm.start()

func _on_output_tm_timeout():
	panel.hide()
	for node in vbox.get_children(): node.queue_free()
