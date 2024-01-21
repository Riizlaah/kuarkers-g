extends Node3D

@onready var sun = $SUN
@onready var moon = $MOON
@onready var w_env : WorldEnvironment = $W_ENV
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

@export_category("Time")
@export var day_length = 800.0
@export var s_time = 0.3
@export var sun_c : Gradient
@export var sun_ins : Curve
@export var moon_c : Gradient
@export var moon_ins : Curve
@export var sky_top_c : Gradient
@export var sky_horizon_c : Gradient

func _ready():
	const h_con = 2.25
	var height: float = 2.25
	time_rate = 1.0 / day_length
	time = s_time
	GameManager.players = make_uniq(GameManager.players)
	for i in GameManager.players:
		var c_player = player_s.instantiate()
		c_player.name = str(i)
		add_child(c_player)
		c_player.position = Vector3(3, height, 3)
		c_player.lb_name.text = GameManager.players[i]["nama"]
		c_player.setRandomItem()
		height += h_con
	multiplayer.peer_disconnected.connect(peer_disconnect)
	multiplayer.server_disconnected.connect(server_disconnect)

func _process(delta):
	noise_offset += time * 0.05
	noise.set("offset", Vector3(noise_offset, 0, 0))
	time += time_rate * delta
	if time >= 1.0:
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
	get_tree().change_scene_to_file("res://scene/main.tscn")


