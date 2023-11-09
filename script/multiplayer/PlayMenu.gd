extends Panel

@onready var hostmenu = $HostMenu
@onready var joinmenu = $JoinMenu
@onready var tabcont: TabContainer = $TabContainer
@onready var world_opt := $HostMenu/OptionButton
@onready var player_auth := $HostMenu/OptionButton2
@onready var use_time := $HostMenu/CheckBox
@onready var world_time := $HostMenu/OptionButton3

var port = 8080
var address

enum w_opt {
	klasik = 0
}
enum p_auth {
	admin = 0,
	user = 1,
	pengunjung = 2
}
enum t_start {
	pagi = 0,
	siang = 1,
	sore = 2,
	malam = 3
}

func _on_close_pressed():
	hide()

func _on_tab_container_tab_changed(tab: int):
	if tab == 0:
		joinmenu.hide()
		hostmenu.show()
	elif tab == 1:
		hostmenu.hide()
		joinmenu.show()

func _on_buat_pressed():
	var world_option = world_opt.get_selected_id()
	var player_authority = player_auth.get_selected_id()
	var use_time2 = use_time.button_pressed
	var time_start = world_time.get_selected_id()
	Hostinfo.host = true
	Hostinfo.player_auth = player_authority
	Hostinfo.use_time = use_time2
	Hostinfo.time_start = time_start
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	pass
