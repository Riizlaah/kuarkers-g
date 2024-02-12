extends TabContainer

@onready var label = $Umum/Hbox/Label
@onready var pn_edit = $Umum/Hbox/LineEdit
@onready var label2 = $Umum/Hbox2/Label
@onready var senv = $Umum/Hbox2/Hslider
@onready var label3 = $Grafik/Hbox3/Label
@onready var r_dist = $Grafik/Hbox3/Hslider
@onready var label4 = $Grafik/Hbox4/Label
@onready var scale_3d = $Grafik/Hbox4/Hslider
@onready var label5 = $Grafik/Hbox5/Label4
@onready var shadow = $Grafik/Hbox5/CheckButton
@onready var label6 = $Umum/Hbox3/Label
@onready var sc_j = $Umum/Hbox3/Hslider

func _ready():
	load_file()
	await get_tree().create_timer(0.3).timeout
	pn_edit.text = Settings.p_name
	senv.value = Settings.senv * 100
	r_dist.value = Settings.r_dist * 0.01
	scale_3d.value = Settings.scale_3d
	label4.text = "Skala Resolusi : " + str(scale_3d.value) + " "
	sc_j.value = Settings.s_joystick
	_on_check_button_toggled(Settings.shadow_enabled)

func load_file():
	var data = FileAccess.get_file_as_string("user://conf.json")
	if data.is_empty():
		return
	data = JSON.parse_string(data)
	Settings.p_name = data["p_name"]
	Settings.senv = data["senv"]
	Settings.shadow_enabled = data["shadow_enabled"]
	Settings.r_dist = data["r_dist"]
	Settings.scale_3d = data["scale_3d"]
	Settings.s_joystick = data["s_joystick"]
func save_file():
	var data = {
		"p_name": Settings.p_name,
		"senv": Settings.senv,
		"shadow_enabled": Settings.shadow_enabled,
		"scale_3d": Settings.scale_3d,
		"r_dist": Settings.r_dist,
		"s_joystick": Settings.s_joystick
	}
	data = JSON.stringify(data)
	var file = FileAccess.open("user://conf.json", FileAccess.WRITE)
	file.store_string(data)
	file.close()

func _on_senv_changed(value):
	label2.text = "Sensivitas : " + str(value) + " "
	Settings.senv = value * 0.01

func _on_r_dist_changed(value):
	value = value * 100
	label3.text = "Jarak Render : " + str(value) + " "
	Settings.r_dist = value

func _on_scale_3d_changed(value):
	label4.text = "Skala Resolusi : " + str(value) + " "
	Settings.scale_3d = value

func _on_check_button_toggled(toggled_on):
	if toggled_on:
		shadow.text = "Nyala"
	else:
		shadow.text = "Mati"
	Settings.shadow_enabled = toggled_on

func _on_close_pressed():
	get_parent().anim.play_backwards("setting")
	await get_tree().create_timer(0.3).timeout
	hide()
	get_parent().panel.hide()
	save_file()

func _on_pn_edit_text_changed(new_text: String):
	if new_text.is_empty(): return
	if new_text.contains(" "):
		new_text = new_text.replace(" ", "_")
	Settings.p_name = new_text

func _on_sc_joystick_changed(value):
	Settings.s_joystick = value
	label6.text = "Skala Joystik : " + str(value) + " "
