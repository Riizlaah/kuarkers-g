extends Node3D
class_name WorldLoader

signal receive_msg(msg: String)
signal save_completed
signal w_added

const times = [0.23, 0.48, 0.725, 0.78, 0.98]
const throw_i = preload("res://scene/throwable_melee.tscn")
const explodable = preload("res://scene/explodable_item.tscn")
const rocket_s = preload("res://scene/rocket.tscn")

@onready var sun = $SUN
@onready var moon = $MOON
@onready var w_env : WorldEnvironment = $W_ENV
@onready var resource_preloader = $ResourcePreloader
@onready var vbox = $CanvasLayer/Control/Panel/SCont/Vbox
@onready var panel = $CanvasLayer/Control/Panel
@onready var output_tm = $output_tm
@onready var s_cont = $CanvasLayer/Control/Panel/SCont
@onready var canvas_layer = $CanvasLayer
@onready var broadcaster = $Broadcaster
@onready var players = $players
@onready var mp_spawner = $MPSpawner

var noise = preload("res://resources/other/Noise1.tres")
var main_menu = preload("res://scene/main_menu.tscn")
var items: Dictionary = {'': null}
var time : float
var time_rate : float
var noise_offset := 0.05
var items_arr: Array
var world: WorldTemplate
var quests_started : Dictionary
var player_nodes: Dictionary
var chat_visible := false
var world_spawn: Vector3
var current_saved_data := {}
var saved_player_datas := {}
var world_added := false

@export_category("Other")
@export var texture_t: Texture2D
@export var player_s : PackedScene
@export var musuh: PackedScene
@export var w_npc: PackedScene
@export var pickable_sc: PackedScene
@export var output_lb: PackedScene
@export var proc_gen: PackedScene

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
	GManager.world = self
	GManager.stop_main_music()
	load_items()
	configure_graphics()
	setup_signal()
	if !multiplayer.is_server():
		fetch_data.rpc_id(1, multiplayer.get_unique_id())
		GManager.send_player_info.rpc_id(1, multiplayer.get_unique_id(), Settings.player_uuid, Settings.player_name, Settings.player_color.to_html())
	else:
		load_world()
	time_rate = 1.0 / day_length
	time = s_time
	set_physics_process(false)

@rpc("any_peer")
func fetch_data(from):
	var data = get_save_data()
	send_data.rpc_id(from, data)

@rpc("any_peer")
func send_data(world_data):
	GManager.world_data = world_data
	load_world()

func world_loaded():
	$Loading.hide()
	w_added.emit()
	world_added = true
	if multiplayer.is_server():
		broadcaster.start_broadcast()
		player_connected(1)
		GManager.send_player_info(1, Settings.player_uuid, Settings.player_name, Settings.player_color.to_html())
		world.players_added()
		save_world(false)
		return
	world.players_added()

func player_connected(id: int):
	GManager.send_game_addr.rpc(GManager.game_addr)
	var new_player = player_s.instantiate()
	new_player.name = str(id)
	new_player.position = world_spawn
	players.add_child(new_player)
	new_player.hide()
	new_player.process_mode = Node.PROCESS_MODE_DISABLED

func player_data_added(id: int):
	var player: Player3D = players.get_node(str(id))
	if !world_added: await w_added
	player.set_player_data()
	player.show()
	player.process_mode = Node.PROCESS_MODE_INHERIT

func load_world():
	seed(GManager.world_data.seed)
	var world_type = GManager.world_data.type
	if world_type < 1:
		world_type = 1
	if world_type > 3:
		OS.alert("apa kamu modder?", "?")
		get_tree().quit()
		return
	world = GManager.limited_worlds[world_type].instantiate()
	add_child(world)

func get_save_data():
	if multiplayer.get_unique_id() != 1: return
	var world_data = GManager.world_data
	for player in player_nodes.values():
		saved_player_datas[player.uuid] = {
			'pos': player.position,
			'rot': player.rotation,
			'head_rot': player.get_head_rotation(),
			'extra_data': player.get_data()
		}
	var curr_date = Time.get_datetime_dict_from_system()
	curr_date.erase('weekday')
	curr_date.erase('dst')
	var save = {
		'name': world_data.name,
		'seed': world_data.seed,
		'gamemode': world_data.gamemode,
		'type': world_data.type,
		'world_spawn': world_spawn,
		'players': saved_player_datas,
		'extra_data': world.save_world(),
		'version': Settings.GAME_VERSION,
		'date': curr_date
	}
	return save

func save_world(with_img: bool):
	var world_data = GManager.world_data
	current_saved_data = get_save_data()
	var save_dir = "world/"+world_data.save_dir
	FileSystem.mkdir(save_dir)
	FileSystem.write(save_dir+"/world.dat", current_saved_data)
	if with_img == true:
		player_nodes[GManager.players[1].name].hide_2d()
		canvas_layer.hide()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(FileSystem.base_path+"/"+save_dir+"/world.png")
	FileSystem.chdir_base()

func load_items():
	for res in resource_preloader.get_resource_list():
		var item: ItemData = resource_preloader.get_resource(res)
		items[res] = item

func configure_graphics():
	if Settings.sky_graphic == Settings.SkyGraphics.Low:
		w_env.environment.background_mode = Environment.BG_COLOR
	else:
		if Settings.sky_graphic == Settings.SkyGraphics.High:
			sky_mat.sky_cover = sky_texture
		w_env.environment.sky = Sky.new()
		w_env.environment.sky.sky_material = sky_mat
	get_viewport().scaling_3d_scale = Settings.scale_3d

func setup_signal():
	multiplayer.server_disconnected.connect(server_disconnected)
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	receive_msg.connect(receiving_msg)

func _process(delta):
	time += time_rate * delta
	if time > 1.0: time = 0.0
	if Settings.sky_graphic == Settings.SkyGraphics.Low:
		w_env.environment.set_bg_color(sky_horizon_c.sample(time))
		return
	process_sky(delta)

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
	#visibility sun and moon
	sun.visible = sun.light_energy > 0
	moon.visible = moon.light_energy > 0
	#Environment
	sky_mat.set("sky_top_color", sky_top_c.sample(time))
	sky_mat.set("sky_horizon_color", sky_horizon_c.sample(time))
	sky_mat.set("ground_bottom_color", sky_top_c.sample(time))
	sky_mat.set("ground_horizon_color", sky_horizon_c.sample(time))

func peer_disconnected(id: int):
	if multiplayer.is_server():
		save_world(false)
		await save_completed
		players.get_node(str(id)).queue_free()
	player_nodes.erase(GManager.players[id].name)
	GManager.players.erase(id)

@rpc("any_peer")
func disconnect_peer(id):
	multiplayer.multiplayer_peer.disconnect_peer(id)

func server_disconnected():
	if multiplayer.is_server():
		await save_world(true)
		broadcaster.stop_server()
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
func give_item(player_name, item_name, stack_count):
	if stack_count > 1 and !items[item_name].stack: stack_count = 1
	player_nodes[player_name].fill_empty_slot_with_item(items[item_name], stack_count)

@rpc("any_peer", "call_local", "reliable")
func sync_npc_hp(npc_name, hp):
	world.get_node("NPCs").get_node(npc_name).hp = hp

@rpc("any_peer", "call_local", "reliable")
func sync_npc_target(npc_name, target_name):
	world.get_node("NPCs").get_node(npc_name).target_node = get_node(target_name)

func sync_npc_dialogues(npc_name, dialogues):
	world.get_node("NPCs").get_node(npc_name).dialogues = dialogues

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

func _autosave():
	save_world(false)
