extends Node3D

const times = [0.23, 0.48, 0.725, 0.78, 0.98]

@onready var sun = $SUN
@onready var moon = $MOON
@onready var w_env : WorldEnvironment = $W_ENV
@onready var animation_player = $AnimationPlayer

@onready var noise = load("res://resources/other/Noise1.tres")
var ResItemArr = Func.ResItemArr
var WpItemArr = [
	ResItemArr[2],
	ResItemArr[4],
	ResItemArr[6],
	ResItemArr[8],
	ResItemArr[11]
]
var time : float
var time_rate : float
var noise_offset := 0.05
@export_category("Other")
@export var player_s : PackedScene
@export var musuh: PackedScene
@export var w_npc: PackedScene

@export_category("Time")
@export var day_length = 1000.0
@export var s_time = 0.3
@export var sun_c : Gradient
@export var sun_ins : Curve
@export var moon_c : Gradient
@export var moon_ins : Curve
@export var sky_top_c : Gradient
@export var sky_horizon_c : Gradient

func _ready():
	animation_player.play("mov1")
	get_viewport().scaling_3d_scale = Settings.scale_3d
	sun.shadow_enabled = Settings.shadow_enabled
	const h_con = -1.25
	var height: float = 2.25
	time_rate = 1.0 / day_length
	time = s_time
	GameManager.players = make_uniq(GameManager.players)
	for i in GameManager.players:
		var c_player = player_s.instantiate()
		c_player.name = str(i)
		add_child(c_player)
		c_player.position = Vector3(3, 3, height)
		c_player.nama_player = GameManager.players[i]["nama"]
		c_player.setRandomItem()
		height += h_con
		c_player.ctrl_ui.hide()
	multiplayer.peer_disconnected.connect(peer_disconnect)
	multiplayer.server_disconnected.connect(server_disconnect)

func _process(delta):
	noise_offset += time_rate * 20
	noise.set("offset", Vector3(noise_offset, 0, 0))
	time += time_rate * delta
	if time > 1.0:
		time = 0.0
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
	w_env.environment.sky.sky_material.set("sky_top_color", sky_top_c.sample(time))
	w_env.environment.sky.sky_material.set("sky_horizon_color", sky_horizon_c.sample(time))
	w_env.environment.sky.sky_material.set("ground_bottom_color", sky_top_c.sample(time))
	w_env.environment.sky.sky_material.set("ground_horizon_color", sky_horizon_c.sample(time))

func make_uniq(dict: Dictionary):
	var not_dup = [""]
	var count = 1
	for i in dict:
		var nilai = dict[i]["nama"]
		if nilai in not_dup:
			dict[i]["nama"] = "%s-%d" % [nilai, count]
			count += 1
		else:
			not_dup.append(nilai)
	return dict

func peer_disconnect(id: int):
	await get_tree().create_timer(0.2).timeout
	var player = get_node(str(id))
	player.queue_free()

func server_disconnect():
	GameManager.players.clear()
	get_tree().change_scene_to_file("res://scene/main.tscn")

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


