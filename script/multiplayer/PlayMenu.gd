extends Panel


@onready var lineEdit = $MarginContainer/HostMenu/Hbox/LineEdit
@onready var lb_player = $MarginContainer/HostMenu/Hbox/Label
@onready var lb_info = $MarginContainer/HostMenu/Label
@onready var start_button = $MarginContainer/HostMenu/Hbox/Start
@onready var lined_ip = $MarginContainer/HostMenu/Hbox2/LineEdit
@onready var lined_port = $MarginContainer/HostMenu/Hbox2/LineEdit2

var scene = preload("res://scene/world.tscn")
var port: int
var ip_addr: String
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
	tg_visible(false)
@rpc("any_peer", "call_local")
func disconnect_peer(id):
	GameManager.players.erase(id)

func _on_buat_pressed():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port)
	if error != OK:
		return
	var ips = IP.get_local_addresses()
	ip_addr = ips[1]
	#var udp = PacketPeerUDP.new()
	#udp.bind(9001)
	#udp.set_broadcast_enabled(true)
	#udp.put_packet(PackedByteArray([0]))
	#var paket = udp.get_packet()
	#print(udp.get_packet_ip())
	multiplayer.multiplayer_peer = peer
	if lineEdit.text.length() == 0:
		lineEdit.text = "Hegers"
	tg_visible(true)
	sendInfo(Settings.p_name, multiplayer.get_unique_id())
	lb_player.text = "Player : " + str(GameManager.players.size())
	start_button.show()
	set_interface(ip_addr, port)

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
			if i != 1:
				set_interface.rpc_id(i, GameManager.interfaces['ip'], GameManager.interfaces['port'])

@rpc("any_peer", "call_local")
func load_game():
	get_tree().change_scene_to_packed(scene)

@rpc("any_peer")
func set_interface(ip: String, port1: int):
	GameManager.interfaces['ip'] = ip
	GameManager.interfaces['port'] = port1
	lb_info.text = "IP: " + GameManager.interfaces['ip'] + " || PORT: " + str(GameManager.interfaces['port'])

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
		server_disconnected.rpc()
		start_button.hide()
	else:
		disconnect_peer.rpc(peer_id)
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		tg_visible(false)

func _on_join_pressed():
	var ip_adr: String = lined_ip.text
	var port3: String = lined_port.text
	if !ip_adr.is_valid_ip_address():
		OS.alert("Bukan alamat ip yang valid!", "Peringatan")
		return
	if !port3.is_valid_int():
		OS.alert("Bukan port yang valid!", "Peringatan")
		return
	var port4 = port3.to_int()
	joinByIp(ip_adr, port4)
