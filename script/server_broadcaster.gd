extends Node

const BR_PORT := GManager.BR_PORT
const LT_PORT := GManager.LT_PORT
const MULTICAST_ADDR := GManager.MULTICAST_ADDR
var server_port := 0
var server_ip := ""
var server_data := {}
var br_peer: PacketPeerUDP

func _ready():
	if !multiplayer.is_server():
		queue_free()
		return
	start_broadcast()

func start_broadcast():
	server_data = GManager.server_data
	server_data.player_count = GManager.players.size()
	br_peer = PacketPeerUDP.new()
	if br_peer.bind(BR_PORT) != OK:
		OS.alert("Gagal 'broadcasting' server", "Peringatan")
		get_tree().quit()
		return
	br_peer.set_broadcast_enabled(true)
	if !OS.is_debug_build(): br_peer.set_dest_address(MULTICAST_ADDR, LT_PORT)
	else: br_peer.set_dest_address("0.0.0.0", LT_PORT)
	$Timer.start()

func set_max_players(max_players: int):
	server_data.max_players = max_players

func _on_broadcasting():
	await get_tree().create_timer(0.5).timeout
	server_data.player_count = GManager.players.size()
	var packet = JSON.stringify(server_data).to_utf8_buffer()
	br_peer.put_packet(packet)

func stop_server():
	br_peer.close()
	br_peer = null
	GManager.server_data = {}

func _exit_tree():
	if is_instance_valid(br_peer): stop_server()
