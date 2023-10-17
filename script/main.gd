extends Control

@onready var fov_lb = $ColorRect/FOV_LB
@onready var fov = $ColorRect/FOV
@onready var senv_lb = $ColorRect/SENV_LB
@onready var senv = $ColorRect/SENV
@onready var text_edit = $ColorRect/TextEdit

func _ready():
	fov_lb.text = "FOV : " + str(Settings.fov)
	senv_lb.text = "Sensivitas : " + str(Settings.senv * 100)
	text_edit.text = "EL_HEKER"
	fov.value = Settings.fov
	senv.value = Settings.senv * 100

func _on_main_pressed():
	get_tree().change_scene_to_file("res://scene/world.tscn")
	pass

func _on_quit_pressed():
	get_tree().quit()
	pass

func _on_setting_pressed():
	$ColorRect.show()
	pass # Replace with function body.

func _on_close_pressed():
	$ColorRect.hide()
	pass # Replace with function body.

func _on_fov_value_changed(value: int):
	fov_lb.text = "FOV : " + str(value)
	Settings.fov = value

func _on_senv_value_changed(value: float):
	senv_lb.text = "Sensivitas : " + str(value)
	Settings.senv = value*0.01

func _on_text_edit_text_changed():
	if check_s_n_t(text_edit.text) == true:
		text_edit.text = text_set(text_edit.text)
	#Settings.p_name = text_edit.text
	#print(Settings.p_name)
	pass

func text_set(text: String):
	text = text.replace("\n", "")
	text = text.replace(" ", "")
	return text

func check_s_n_t(text: String):
	return text.find("\n") != -1 or text.find(" ") != -1

func _on_save_pressed():
	Settings.p_name = text_edit.text
	#print(Settings.p_name)
