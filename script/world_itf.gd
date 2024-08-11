class_name WorldItf
extends Panel

signal world_clicked(idx: int)

const gamemode_str = {
	0: 'Survival'
}

var world_data: Dictionary
var selected := false:
	set(val):
		selected = val
		if val == true:
			self_modulate = Color.GRAY
		else:
			self_modulate = Color.WHITE

func load_data(data: Dictionary):
	$Vbox/thumbn.texture = data.tmb
	$Vbox/w_name.text = data.name
	$Vbox/w_info.text = format_world_info(gamemode_str[data.gamemode], data.date)
	world_data = data

func format_world_info(mode: String, old: Dictionary, simple = true):
	const diff_list = {
		'year': 'tahun',
		'month': 'bulan',
		'day': 'hari',
		'hour': 'jam',
		'minute': 'menit',
		'second': 'detik'
	}
	var text: String = "Mode " + mode + "; "
	var now = Time.get_datetime_dict_from_system()
	var difference = {}
	for k in old.keys():
		var diff = (now[k] - old[k])
		if diff > 0:
			difference[k] = diff
	if difference.is_empty() == true: return "baru saja"
	for k in difference.keys():
		text = text + str(difference[k]) + " " + diff_list[k] + ", "
		if simple == true: break
	return text.trim_suffix(", ") + " yang lalu"

func _on_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		world_clicked.emit(get_index())
