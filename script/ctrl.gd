extends Control

signal right_click

@onready var pause_bg = $"../pause_bg"
@onready var charr = $".."
@onready var left_btn = $Left
@onready var jump_btn = $JUMP
@onready var label = $"../pause_bg/PAUSE_BG/Label"
@onready var tool = $Hbox/Tool
@onready var vbox_tool = $Hbox/Vbox

func _ready():
	await get_tree().create_timer(0.2).timeout
	if multiplayer.is_server():
		label.text = "Host"
		tool.show()
		return
	label.text = "Client"

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
	var dir = -charr.cam.global_transform.basis.z + (charr.cam.global_transform.basis * Vector3(0,5,-38))
	get_node("/root/World").spawn_musuh.rpc(dir)

func _tool_toggled(toggled_on: bool):
	if toggled_on:
		vbox_tool.show()
	else:
		vbox_tool.hide()
