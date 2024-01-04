extends VBoxContainer

var broadcaster
var listner = PacketPeerUDP.new()
var l_port = 8991
var b_port = 8990
var btn_lan = preload("res://scene/lan_list.tscn")
@onready var broadcastTimer = $Timer
@onready var serverList = $Scroll/ServerList
@onready var playMenu = $"../.."
@onready var label = $"../../../Label"

var r_info = {"nama":"", "port": 0, "jumlah": 0, "host": ""}

func _ready():
	var ok = listner.bind(l_port,"127.0.0.1")
	if ok != OK:
		label.text = "false"

func _process(_delta):
	if listner.get_available_packet_count() > 0:
		var serverip = listner.get_packet_ip()
		var bytes = listner.get_packet()
		var data = bytes.get_string_from_ascii()
		r_info = JSON.parse_string(data)
		if serverip.is_empty():
			return
		var node_s = find_node(serverip.replace(".", "_"))
		if node_s != null:
			node_s.jumlah = r_info["jumlah"]
			return
		var c_btn = btn_lan.instantiate()
		serverList.add_child(c_btn)
		c_btn.name = serverip
		c_btn.ip = serverip
		c_btn.port = r_info["port"]
		c_btn.nama = r_info["nama"]
		c_btn.host = r_info["host"]
		c_btn.jumlah = r_info["jumlah"]
		c_btn.joinGame.connect(playMenu.joinByIp)

func find_node(nama):
	var nodes = serverList.get_children()
	for node in nodes:
		if node.name == nama:
			return node
	return null
@rpc("call_local")
func clear_server():
	var nodes = serverList.get_children()
	for node in nodes:
		node.queue_free()

func setBroadcast(nama, port: int):
	r_info["nama"] = nama
	r_info["port"] = port
	r_info["jumlah"] = GameManager.players.size()
	r_info["host"] = Settings.p_name
	broadcaster = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	broadcaster.set_dest_address("127.0.0.1", l_port)
	var ok = broadcaster.bind(b_port)
	if ok != OK:
		print('binding b port failed')
	broadcastTimer.start()

func _on_timer_timeout():
	var data = JSON.stringify(r_info)
	data = data.to_ascii_buffer()
	broadcaster.put_packet(data)

func close_broadcast():
	broadcastTimer.stop()
	clear_server.rpc()

func close():
	listner.close()
	broadcastTimer.stop()
	if broadcaster != null:
		broadcaster.close()

func _exit_tree():
	close()
