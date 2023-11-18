extends Node3D

signal player_disc(id: int)
signal host_disconnected

@onready var sun = $SUN
@onready var moon = $MOON
@onready var w_env : WorldEnvironment = $W_ENV
@onready var noise = load("res://resources/other/Noise1.tres")
@onready var ResItemArr = [
	preload("res://resources/items/akm_i.tres"),
	preload("res://resources/items/ammo_i.tres"),
	preload("res://resources/items/arit_i.tres"),
	preload("res://resources/items/awm_i.tres"),
	preload("res://resources/items/botol_i.tres"),
	preload("res://resources/items/donat_i.tres"),
	preload("res://resources/items/golok_i.tres"),
	preload("res://resources/items/grenade_i.tres"),
	preload("res://resources/items/kapak_i.tres"),
	preload("res://resources/items/med_i.tres"),
	preload("res://resources/items/mp5_i.tres"),
	preload("res://resources/items/pistol_i.tres"),
	preload("res://resources/items/rocket_i.tres"),
	preload("res://resources/items/rpg_i.tres")
	]
@onready var WpItemArr = [
	preload("res://resources/items/golok_i.tres"),
	preload("res://resources/items/kapak_i.tres"),
	preload("res://resources/items/arit_i.tres"),
	preload("res://resources/items/pistol_i.tres"),
	preload("res://resources/items/botol_i.tres")
]

var time : float
var time_rate : float
var noise_offset := 0.05
@export_category("Other")
@export var player_s : PackedScene = preload("res://scene/char.tscn")
@export var main_s : PackedScene = preload("res://scene/main.tscn")

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
	time_rate = 1.0 / day_length
	time = s_time
	player_disc.connect(free_player)
	host_disconnected.connect(free_host)
	GameManager.players = make_uniq(GameManager.players)
	for i in GameManager.players:
		var c_player = player_s.instantiate()
		c_player.name = str(i)
		add_child(c_player)
		c_player.position = Vector3(0, 3, 0)
		c_player.lb_name.text = GameManager.players[i]["nama"]
		c_player.setRandomItem()

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

func free_player(id: int):
	var player = get_node("/root/World/%d" % id)
	player.death(true)

func free_host():
	var nodes = get_children(true)
	for node in nodes:
		node.queue_free()
	ch_scene.rpc()

@rpc("any_peer", "call_local")
func ch_scene():
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_packed(main_s)

