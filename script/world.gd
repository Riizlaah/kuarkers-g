extends Node3D


@onready var sun = $SUN
@onready var moon = $MOON
@onready var w_env : WorldEnvironment = $W_ENV
@onready var rigidBody = $RigidBody3D
@onready var noise = load("res://resources/other/Noise1.tres")

var time : float
var time_rate : float
var noise_offset := 0.05
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
	await get_tree().create_timer(2).timeout
	rigidBody.apply_impulse(Vector3(0,0,-10) * 5)
	#var test = PhysicsServer3D.new()

func _process(delta):
	noise_offset += time * 0.15
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
