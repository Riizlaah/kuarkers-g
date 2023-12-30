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

var r_info = {"nama":"", "port": 0}

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
		print(node_s)
		if node_s != null:
			return
		var c_btn = btn_lan.instantiate()
		serverList.add_child(c_btn)
		c_btn.name = serverip
		c_btn.ip = serverip
		c_btn.port = r_info["port"]
		c_btn.text = r_info["nama"]
		c_btn.joinGame.connect(playMenu.joinByIp)

func find_node(nama):
	var nodes = serverList.get_children()
	print(nodes)
	for node in nodes:
		if node.name == nama:
			return node
	return null

func setBroadcast(nama, port: int):
	r_info["nama"] = nama
	r_info["port"] = port
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

func close():
	listner.close()
	broadcastTimer.stop()
	if broadcaster != null:
		broadcaster.close()

func _exit_tree():
	close()
