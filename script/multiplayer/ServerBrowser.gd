extends VBoxContainer

var broadcaster
var listner = PacketPeerUDP.new()
var l_port = 8911
var b_port = 8912
var btn_lan = preload("res://scene/lan_list.tscn")
@onready var broadcastTimer = $Timer
@onready var serverList = $Scroll/ServerList
@onready var playMenu = $"../.."

var r_info = {"nama":"nama"}

func _ready():
	#listner = PacketPeerUDP.new()
	var ok = listner.bind(l_port)
	if ok == OK:
		print('binding l port succeed')
	else:
		print('binding l port fail')

func _process(_delta):
	if listner.get_available_packet_count() > 0:
		var serverip = listner.get_packet_ip()
		#var serverport = listner.get_packet_port()
		var bytes = listner.get_packet()
		var data = bytes.get_string_from_ascii()
		r_info = JSON.parse_string(data)
		var node_s = serverList.get_node_or_null(r_info["nama"])
		if weakref(node_s) == null:
			var c_btn = btn_lan.instantiate()
			c_btn.name = r_info["nama"]
			c_btn.ip = serverip
			c_btn.text = r_info["nama"]
			serverList.add_child(c_btn)
			c_btn.joinGame.connect(playMenu.joinByIp)
		else:
			node_s.ip = serverip
			node_s.text = r_info["nama"]
			#print("LAN added")
		#print(serverip + "\n" + str(serverport) + "\n" + r_info)

func setBroadcast(nama):
	r_info.nama = nama
	broadcaster = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	var ok = broadcaster.bind(b_port)
	if ok == OK:
		print('binding b port succeed')
	else:
		print('binding b port fail')
	broadcastTimer.start()

func _on_timer_timeout():
	print('siaran...')
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


func _on_button_pressed():
	pass # Replace with function body.
