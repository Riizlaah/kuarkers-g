extends VBoxContainer

var broadcaster
var listner = PacketPeerUDP.new()
var l_port = 8991
var b_port = 8990
@onready var broadcastTimer = $Timer
@onready var playMenu = $"../.."
@onready var label = $"../../../Label"

var r_info = {"nama":"", "port": 0, "jumlah": 0, "host": ""}

func _ready():
	var ok = listner.bind(l_port,"127.0.0.1")
	if ok != OK:
		label.text = "false"

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

func close():
	listner.close()
	broadcastTimer.stop()
	if broadcaster != null:
		broadcaster.close()

func _exit_tree():
	close()
