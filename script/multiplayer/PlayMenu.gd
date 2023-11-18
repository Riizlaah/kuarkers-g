extends Panel


@onready var lineEdit = $MarginContainer/HostMenu/HBoxContainer/LineEdit
@onready var s_browser = $MarginContainer/HostMenu
@onready var lb_player = $MarginContainer/HostMenu/HBoxContainer/Label
var scene = preload("res://scene/world.tscn")
var port = 8910
var address = "127.0.0.1"
var peer

func _ready():
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)

func _on_close_pressed():
	hide()

#client only
func connected_to_server():
	print('Terkoneksi ke server')
	sendInfo.rpc_id(1, Settings.p_name, multiplayer.get_unique_id())
func connection_failed():
	multiplayer.multiplayer_peer = null
	print('koneksi gagal')
func server_disconnected():
	print('Server berhenti')

func _on_buat_pressed():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port)
	if error != OK:
		return
	multiplayer.multiplayer_peer = peer
	if lineEdit.text.length() == 0:
		lineEdit.text = "Hegers"
	tg_visible(true)
	sendInfo(Settings.p_name, multiplayer.get_unique_id())
	lb_player.text = "Player : " + str(GameManager.players.size())
	s_browser.setBroadcast(lineEdit.text)
	$MarginContainer/HostMenu/HBoxContainer/Start.show()

func joinByIp(ip):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer

#rpc
@rpc("any_peer")
func sendInfo(nama: String, id: int) -> void:
	if !GameManager.players.has(id):
		GameManager.players[id] = {
			"nama": nama,
			"id": id
		}
	if multiplayer.is_server():
		for i in GameManager.players:
			sendInfo.rpc(GameManager.players[i].nama, i)

@rpc("any_peer", "call_local")
func load_game():
	get_tree().change_scene_to_packed(scene)

func _on_start_pressed():
	load_game.rpc()

func tg_visible(tg: bool):
	for node in get_tree().get_nodes_in_group("host_ui"):
		node.visible = !tg
	for node in get_tree().get_nodes_in_group("wait_ui"):
		node.visible = tg


func _on_quit_pressed():
	if multiplayer.is_server():
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		GameManager.players.clear()
		tg_visible(false)
		$MarginContainer/HostMenu/HBoxContainer/Start.hide()
	else:
		GameManager.players.erase(multiplayer.multiplayer_peer.get_unique_id())
		multiplayer.multiplayer_peer.close()
		tg_visible(false)
