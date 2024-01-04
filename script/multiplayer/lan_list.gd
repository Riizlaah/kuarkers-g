extends Panel

@onready var label1 = $Vbox/Label
@onready var label2 = $Vbox/Label2

signal joinGame(ip: String, port: int)
var ip: String
var port: int
var nama: String
var host: String
var jumlah : int : set = setlabel

func setlabel(val):
	jumlah = val
	label2.text = host + " / Jumlah pemain : " + str(jumlah)
	label1.text = nama

func _on_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		self_modulate = Color.DIM_GRAY
		joinGame.emit(ip, port)
	else:
		self_modulate = Color.GRAY
