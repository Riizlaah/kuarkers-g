extends Control

@onready var fov_lb = $ColorRect/FOV_LB
@onready var fov = $ColorRect/FOV
@onready var senv_lb = $ColorRect/SENV_LB
@onready var senv = $ColorRect/SENV
@onready var text_edit = $ColorRect/TextEdit
@onready var PlayMenu = $PlayMenu
@onready var infomenu = $InfoMenu
@onready var anim = $AnimationPlayer
@onready var setting = $ColorRect
@onready var bg_texture = $bg_texture

@export var texture_arr : Array[Texture]

func _ready():
	multiplayer.multiplayer_peer = null
	aready()
	load_file()
	await get_tree().create_timer(0.5).timeout
	fov_lb.text = "FOV : " + str(Settings.fov)
	senv_lb.text = "Sensivitas : " + str(Settings.senv * 100)
	text_edit.text = "EL_HEKER"
	fov.value = Settings.fov
	senv.value = Settings.senv * 100
	#ProjectSettings.get_setting()

func load_file():
	var data = FileAccess.get_file_as_string("user://conf.json")
	if data.is_empty():
		return
	data = JSON.parse_string(data)
	Settings.p_name = data["p_name"]
	Settings.fov = data["fov"]
	Settings.senv = data["senv"]

func save_file():
	var data = {
		"p_name": Settings.p_name,
		"fov": Settings.fov,
		"senv": Settings.senv
	}
	data = JSON.stringify(data)
	var file = FileAccess.open("user://conf.json", FileAccess.WRITE)
	file.store_string(data)
	file.close()

func aready():
	bg_texture.texture = texture_arr.pick_random()
	show()
	anim.play("when-ready")
func _on_main_pressed():
	PlayMenu.show()
	anim.play("playmenu")

func _on_quit_pressed():
	get_tree().quit()

func _on_setting_pressed():
	setting.show()
	anim.play("setting")

func _on_close_pressed():
	anim.play_backwards("setting")
	await get_tree().create_timer(0.5).timeout
	setting.hide()

func _on_fov_value_changed(value: int):
	fov_lb.text = "FOV : " + str(value)
	Settings.fov = value
	save_file()

func _on_senv_value_changed(value: float):
	senv_lb.text = "Sensivitas : " + str(value)
	Settings.senv = value*0.01
	save_file()

func _on_text_edit_text_changed(new_text):
	if check_s_n_t(new_text) == true:
		text_edit.text = text_set(new_text)

func text_set(text: String):
	text = text.replace("\n", "")
	text = text.replace(" ", "")
	return text

func check_s_n_t(text: String):
	return text.find("\n") != -1 or text.find(" ") != -1

func _on_info_pressed():
	infomenu.show()

func _on_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		infomenu.hide()

func _on_text_edit_text_submitted(new_text):
	Settings.p_name = new_text
	save_file()

func _on_close1_pressed():
	anim.play_backwards("playmenu")
	await get_tree().create_timer(0.5).timeout
	PlayMenu.hide()
