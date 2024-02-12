extends Control

@onready var PlayMenu = $PlayMenu
@onready var infomenu = $InfoMenu
@onready var anim = $AnimationPlayer
@onready var bg_texture = $bg_texture
@onready var setting = $Setting
@onready var panel = $Panel
@onready var join_menu = $JoinMenu

@export var texture_arr : Array[Texture2D]

func _ready():
	multiplayer.multiplayer_peer = null
	aready()
	await get_tree().create_timer(0.5).timeout


func aready():
	bg_texture.texture = texture_arr.pick_random()
	show()
	anim.play("when-ready")
func _on_main_pressed():
	panel.show()
	PlayMenu.show()
	anim.play("playmenu")

func _on_quit_pressed():
	get_tree().quit()

func _on_setting_pressed():
	panel.show()
	setting.show()
	anim.play("setting")

func _on_info_pressed():
	panel.show()
	infomenu.show()

func _on_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed() and infomenu.visible == true:
		infomenu.hide()
		panel.hide()

func _on_close1_pressed():
	anim.play_backwards("playmenu")
	await get_tree().create_timer(0.3).timeout
	PlayMenu.hide()
	panel.hide()

func _on_close2_pressed():
	anim.play_backwards("joinmenu")
	await get_tree().create_timer(0.3).timeout
	join_menu.hide()
	panel.hide()

func _on_join_pressed():
	panel.show()
	join_menu.show()
	anim.play("joinmenu")
