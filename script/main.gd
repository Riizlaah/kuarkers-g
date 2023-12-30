extends Control

@onready var fov_lb = $ColorRect/FOV_LB
@onready var fov = $ColorRect/FOV
@onready var senv_lb = $ColorRect/SENV_LB
@onready var senv = $ColorRect/SENV
@onready var text_edit = $ColorRect/TextEdit
@onready var PlayMenu = $PlayMenu
@onready var infomenu = $InfoMenu
@onready var anim = $AnimationPlayer

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
	await get_tree().create_timer(0.5).timeout
	anim.play("when-ready")
func _on_main_pressed():
	PlayMenu.show()


func _on_quit_pressed():
	get_tree().quit()


func _on_setting_pressed():
	$ColorRect.show()


func _on_close_pressed():
	$ColorRect.hide()



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

func _on_save_pressed():
	Settings.p_name = text_edit.text
	save_file()

func _on_info_pressed():
	infomenu.show()


func _on_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		infomenu.hide()
