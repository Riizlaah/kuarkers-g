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

const allowed_chars = "012345789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_.- "

func _ready():
	load_data()
	#var rend_dist = Settings.render_distance
	#var chunk_visib = roundi(rend_dist / Settings.CHUNK_SIZE)
	#var chunk_visib = range(-rend_dist, rend_dist)
	#var i3 = 0
	#for i in chunk_visib:
		#for i2 in chunk_visib:
			#i3 += 1

func _on_pname_ch(new_text: String):
	if new_text.is_empty():
		Settings.player_name = ""
		return
	for c in new_text.split():
		if c in allowed_chars: continue
		OS.alert("Nama Pemain mengandung karakter yang tak diperbolehkan, beralih ke default", "Peringatan")
		line_edit.text = Settings.DEFAULT_NAME
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
	Settings.render_distance = value
	viewdist_lb.text = "Jarak Pandang[ ~%s chunk ] : " % (value * 4)

func _on_sky_graphic_selected(index):
	Settings.sky_graphic = index

func load_data():
	var fcont = FileAccess.get_file_as_string("user://setting.json")
	if fcont == "":
		load_default_settings()
		return
	var json = JSON.parse_string(fcont)
	Settings.player_name = json.player_name
	senv_s.value = json.senv
	p_color.color = Color.html(json.player_color)
	Settings.player_color = Color.html(json.player_color)
	scale3d_s.value = json.scale_3d
	viewdist_s.value = json.render_distance
	sky_graphic.select(json.sky_graphic)
	_on_sky_graphic_selected(json.sky_graphic)
	line_edit.text = json.player_name

func load_default_settings():
	line_edit.text = Settings.DEFAULT_NAME
	senv_s.value = Settings.DEFAULT_SENV
	p_color.color = Settings.DEFAULT_COLOR
	scale3d_s.value = Settings.DEFAULT_SCALE3D
	viewdist_s.value = Settings.DEFAULT_RENDER_DIST
	sky_graphic.select(Settings.DEFAULT_SKY)

func save_data():
	if Settings.player_name.is_empty() or Settings.player_name.begins_with(" "):
		Settings.player_name = Settings.DEFAULT_NAME
		line_edit.text = Settings.DEFAULT_NAME
	var data = {
		'player_name': Settings.player_name,
		'player_color': Settings.player_color.to_html(false),
		'senv': Settings.senv * 100,
		'scale_3d': Settings.scale_3d,
		'render_distance': Settings.render_distance,
		'sky_graphic': Settings.sky_graphic
	}
	var file = FileAccess.open("user://setting.json", FileAccess.WRITE)
	file.store_string("")
	file.store_string(JSON.stringify(data))
	file.flush()

func _on_close_pressed():
	get_parent().hide()
	save_data()
