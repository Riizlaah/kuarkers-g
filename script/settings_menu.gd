extends TabContainer

@onready var line_edit = $Umum/LineEdit
@onready var senv_lb = $Umum/Hbox/Label
@onready var senv_s = $Umum/Hbox/HSlider
@onready var p_color = $Umum/Hbox2/PColor
@onready var scale3d_lb = $Grafik/Hbox/Label
@onready var scale3d_s = $Grafik/Hbox/HSlider
@onready var viewdist_lb = $Grafik/Hbox2/Label
@onready var viewdist_s = $Grafik/Hbox2/HSlider
@onready var sky_graphic = $Grafik/Hbox3/sky_graphic

func _ready():
	load_data()

func _on_pname_ch(new_text: String):
	if new_text.contains(" ") or new_text.contains("	"):
		new_text = new_text.replace(" ", "")
		new_text = new_text.replace("	", "")
		line_edit.text = new_text
	if new_text == "":
		Settings.player_name = Settings.DEFAULT_NAME
		line_edit.text = Settings.DEFAULT_NAME
	Settings.player_name = new_text

func _on_senv_ch(value):
	Settings.senv = value * 0.1
	senv_lb.text = "Sensivitas[ %s ] : " % value

func _on_pcolor_ch(color: Color):
	Settings.player_color = color

func _on_scale3d_ch(value):
	Settings.scale_3d = value
	scale3d_lb.text = "Skala 3D[ %sx ] : " % value

func _on_viewr_ch(value):
	Settings.view_dist = value
	viewdist_lb.text = "Jarak Pandang[ %sm ] : " % value

func _on_mcont_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		if !get_global_rect().has_point(event.position):
			hide()
	save_data()

func _on_sky_graphic_selected(index):
	Settings.sky_graphic = index

func load_data():
	if FileAccess.get_file_as_string("user://setting.json") == "": return
	var json = JSON.parse_string(FileAccess.get_file_as_string("user://setting.json"))
	Settings.player_name = json.player_name
	scale3d_s.value = 0
	senv_s.value = 0
	viewdist_s.value = 0
	senv_s.value = json.senv
	p_color.color = Color.html(json.player_color)
	Settings.player_color = Color.html(json.player_color)
	scale3d_s.value = json.scale_3d
	viewdist_s.value = json.view_dist
	sky_graphic.select(json.sky_graphic)
	_on_sky_graphic_selected(json.sky_graphic)
	if json.player_name == "Heker": return
	line_edit.text = json.player_name

func save_data():
	var data = {
		'player_name': Settings.player_name,
		'player_color': Settings.player_color.to_html(false),
		'senv': Settings.senv * 100,
		'scale_3d': Settings.scale_3d,
		'view_dist': Settings.view_dist,
		'sky_graphic': Settings.sky_graphic
	}
	var file = FileAccess.open("user://setting.json", FileAccess.WRITE)
	file.store_string("")
	file.store_string(JSON.stringify(data))
	file.flush()

