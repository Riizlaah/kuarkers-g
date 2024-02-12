extends Control

signal right_click

@onready var pause_bg = $"../pause_bg"
@onready var charr = $".."
@onready var left_btn = $Left
@onready var jump_btn = $JUMP
@onready var label = $"../pause_bg/PAUSE_BG/Label"
@onready var tool = $Hbox/Tool
@onready var vbox_tool = $Hbox/SCont
@onready var join_car = $JoinCar
@onready var fps_label = $Label
var world_node: Node3D
@export var textures: Array[CompressedTexture2D]

func _ready():
	world_node = get_node("/root/World")
	await get_tree().create_timer(0.2).timeout
	if multiplayer.is_server():
		label.text = "-- Host --"
		tool.show()
		return
	else:
		tool.hide()
	label.text = "-- Client --"

func _physics_process(_delta):
	var fps = Engine.get_frames_per_second()
	var str2: String = str(fps)
	if fps < 20.0:
		str2 = str2 + " Yahaha rendahan :v"
	elif fps > 20.0 and fps < 60.0:
		pass
	elif fps > 60.0:
		str2 = str2 + " Ampun bang..."
	fps_label.text = "FPS: " + str2

func _on_pause_pressed():
	pause_bg.visible = true
	visible = false
	charr.pause()

func _on_play_pressed():
	pause_bg.visible = false
	visible = true
	charr.pause()

func _on_keluar_pressed():
	var id = multiplayer.multiplayer_peer.get_unique_id()
	if multiplayer.is_server():
		GameManager.players.clear()
		multiplayer.server_disconnected.emit()
	else:
		GameManager.players.erase(charr.name.to_int())
		multiplayer.multiplayer_peer.disconnect_peer(id)
		get_tree().change_scene_to_file("res://scene/main.tscn")

func _on_jump_gui_input(event):
	if event is InputEventScreenDrag or event is InputEventScreenTouch and event.is_pressed():
		Input.action_press("jump")
		jump_btn.modulate = Color.GRAY
	else:
		Input.action_release("jump")
		jump_btn.modulate = Color.WHITE

func _on_left_button_down():
	left_btn.modulate = Color.GRAY
	Input.action_press("left_click")

func _on_left_button_up():
	left_btn.modulate = Color.WHITE
	Input.action_release("left_click")


func _on_right_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		right_click.emit()

func _on_spawn_enemy_pressed():
	var dir = -charr.cam.global_transform.basis.z + (charr.cam.global_transform * Vector3(0,5,-38))
	world_node.spawn_musuh.rpc(dir)

func _tool_toggled(toggled_on: bool):
	if toggled_on:
		vbox_tool.show()
	else:
		vbox_tool.hide()

func toggle_car_ui(what: int, reset: bool = false):
	if reset == true:
		join_car.hide()
		return
	join_car.show()
	join_car.icon = textures[what]

@rpc("any_peer", "unreliable_ordered")
func toggle_oncar_ui(tgl_on: bool = false):
	if tgl_on:
			for node in get_tree().get_nodes_in_group("notcar_ui"):
				node.show()
			join_car.hide()
			return
	for node in get_tree().get_nodes_in_group("notcar_ui"):
		node.hide()
	join_car.show()

func _on_spawn_wnpc_pressed():
	var pos = -charr.cam.global_transform.basis.z + (charr.cam.global_transform * Vector3(0, 0, -2))
	world_node.spawn_npc1.rpc(pos)

func _on_times_selected(index):
	world_node._change_time.rpc(index)

func _on_play_event_pressed():
	world_node.set_randvent(randi_range(0, 4))
	print('yes')

func _on_stop_event_pressed():
	world_node._stop_event()
