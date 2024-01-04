extends Panel


@onready var lineEdit = $MarginContainer/HostMenu/HBoxContainer/LineEdit
@onready var s_browser = $MarginContainer/HostMenu
@onready var lb_player = $MarginContainer/HostMenu/HBoxContainer/Label
@onready var start_button = $MarginContainer/HostMenu/HBoxContainer/Start
var scene = preload("res://scene/world.tscn")
var port: int
var peer
var time = 60

func _ready():
	port = randi_range(8090, 8989)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.peer_disconnected.connect(peer_connected)
	multiplayer.peer_connected.connect(peer_connected)


func peer_connected(_id):
	await get_tree().create_timer(0.25).timeout
	lb_player.text = "Player : " + str(GameManager.players.size())
func connected_to_server():
	tg_visible(true)
	sendInfo.rpc_id(1, Settings.p_name, multiplayer.get_unique_id())
func connection_failed():
	multiplayer.multiplayer_peer = null
	OS.alert("Koneksi Gagal !", "Peringatan")
@rpc("call_local")
func server_disconnected():
	multiplayer.multiplayer_peer = null
	GameManager.players.clear()
	s_browser.clear_server()
	tg_visible(false)
@rpc("any_peer", "call_local")
func disconnect_peer(id):
	GameManager.players.erase(id)

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
	s_browser.setBroadcast(lineEdit.text, port)
	start_button.show()

func joinByIp(ip, port2):
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port2)
	if err != OK:
		OS.alert("Tidak bisa bergabung, kode eror : " + err, "Peringatan")
		return
	multiplayer.multiplayer_peer = peer

#rpc
@rpc("any_peer")
func sendInfo(nama: String, id: int) -> void:
	if !GameManager.players.has(id):
		GameManager.players[id] = {
			"nama": nama,
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
	var peer_id = multiplayer.multiplayer_peer.get_unique_id()
	if multiplayer.is_server():
		s_browser.close_broadcast()
		server_disconnected.rpc()
		start_button.hide()
	else:
		disconnect_peer.rpc(peer_id)
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		tg_visible(false)

