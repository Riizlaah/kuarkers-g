extends ColorRect

@onready var br_timer = $BRTimer
@onready var room_list = $Mcont/RoomFinder/Scont/Vbox
@onready var room = $Mcont/Room
@onready var room_finder = $Mcont/RoomFinder
@onready var choice = $Mcont/HBoxContainer
@onready var player_list = $Mcont/Room/Scont/PlayerList
@onready var play = $Mcont/Room/HBoxContainer/Play
@onready var rnf = $Mcont/RoomFinder/rnf
@onready var room_info_label = $Mcont/Room/room_info
@onready var main_menu = $"../.."

var plist_s = load("res://scene/player_list.tscn")
var r_list_s = load("res://scene/room_list.tscn")
var world_loader = load("res://scene/world_loader.tscn")

const lt_port = 8083
const br_port = 8082
const multicast_addr = "224.0.0.1"

var ip_addr := ""
var port := 0
var lt_peer := PacketPeerUDP.new()
var br_peer
var iface_name = ""
var room_info: Dictionary

func _ready():
	iface_name = IP.get_local_interfaces()[0].name
	var label = get_node("../../Label2")
	port = randi_range(8085, 10000)
	ip_addr = IP.get_local_addresses()[0]
	if lt_peer.bind(lt_port) != OK: label.show()
	if !OS.is_debug_build(): lt_peer.join_multicast_group(multicast_addr, iface_name)
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.server_disconnected.connect(_server_disconnected)

func _server_disconnected():
	GManager.players.clear()
	multiplayer.multiplayer_peer = null
	reload_s()
	return

func _connected_to_server():
	toggle_view(true)
	send_info.rpc_id(1, multiplayer.get_unique_id(), Settings.player_name, Settings.player_color.to_html(false))

func _connection_failed():
	multiplayer.multiplayer_peer = null
	reload_s()
	return

func _peer_connected(_id):
	await get_tree().create_timer(0.15).timeout
	refresh_list()

func _peer_disconnected(id: int):
	GManager.players.erase(id)
	refresh_list()

func _on_quit_room():
	main_menu._quit_room()
	if multiplayer.is_server():
		multiplayer.server_disconnected.emit()
	else:
		multiplayer.peer_disconnected.emit(multiplayer.get_unique_id())
		multiplayer.multiplayer_peer = null
		GManager.players.clear()
		_on_back_to_choice()

func _on_find_room():
	toggle_view(false)

func _on_create_room():
	main_menu._on_create_room()
	if !visible: show()
	toggle_view(true)
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(port) != OK:
		OS.alert("Gagal membuat server")
		reload_s()
		return
	multiplayer.multiplayer_peer = peer
	send_info(1, Settings.player_name, Settings.player_color.to_html(false))
	refresh_list()
	play.show()
	_broadcast()
	await get_tree().create_timer(0.05).timeout
	update_room_info(room_info.name)

func _on_refresh_room():
	for node in room_list.get_children(): node.queue_free()

func refresh_list():
	for node in player_list.get_children(): node.queue_free()
	for i in GManager.players:
		var new_player = plist_s.instantiate()
		player_list.add_child(new_player)
		if i == 1: new_player.text = GManager.players[i].name + " [host]"
		else: new_player.text = GManager.players[i].name
		if i == multiplayer.get_unique_id(): new_player.text = new_player.text + " [kamu]"

func _broadcast():
	br_peer = PacketPeerUDP.new()
	if br_peer.bind(br_port) != OK:
		OS.alert("Error tidak bisa broadcast")
		reload_s()
		return
	br_peer.set_broadcast_enabled(true)
	if !OS.is_debug_build(): br_peer.set_dest_address(multicast_addr, lt_port)
	else: br_peer.set_dest_address("127.0.0.1", lt_port)
	br_timer.start()

func _on_broadcasting():
	room_info.name = Settings.player_name + OS.get_unique_id().right(4)
	room_info.port = port
	room_info.count = GManager.players.size()
	room_info.ip = ip_addr
	br_peer.put_packet((JSON.stringify(room_info)).to_ascii_buffer())

@rpc("any_peer")
func send_info(id, nama, warna):
	if !GManager.players.has(id):
		GManager.players[id] = {'name': nama, 'color': warna}
	if multiplayer.is_server():
		GManager.players = make_uniq_name(GManager.players)
		for i in GManager.players:
			send_info.rpc(i, GManager.players[i].name, GManager.players[i].color)

func make_uniq_name(dict: Dictionary):
	var not_dup = [""]
	var count = 1
	for i in dict:
		var val = dict[i].name
		if val in not_dup:
			dict[i].name = "%s[%d]" % [val, count]
			count += 1
		else: not_dup.append(val)
	return dict

func _process(_delta):
	if lt_peer.get_available_packet_count() > 0:
		var packet = JSON.parse_string((lt_peer.get_packet()).get_string_from_ascii())
		var room_node = room_list.get_node_or_null(packet.ip.replace('.', '_'))
		if is_instance_valid(room_node) == false:
			var new_room = r_list_s.instantiate()
			new_room.name = packet.ip
			new_room.port = packet.port
			new_room.ip = packet.ip
			room_list.add_child(new_room)
			new_room.text = "%s Room [ %d pemain ]" % [packet.name, packet.count]
			new_room.rn = packet.name
			new_room.join_room.connect(join_room)
			return
		room_node.text = "%s Room [ %d pemain ]" % [packet.name, packet.count]
	if room_list.get_child_count() == 0: rnf.show()
	else: rnf.hide()

func join_room(ip, port1, rn):
	main_menu._on_create_room()
	var peer = ENetMultiplayerPeer.new()
	if peer.create_client(ip, port1) != OK:
		OS.alert("Gagal bergabung dengan server")
		reload_s()
		return
	multiplayer.multiplayer_peer = peer
	update_room_info(rn)
	toggle_view(true)

func reload_s():
	get_tree().reload_current_scene()

func toggle_view(in_room: bool):
	if in_room == false:
		room.hide()
		room_finder.show()
	else:
		room.show()
		room_finder.hide()
	choice.hide()

func update_room_info(nama: String):
	room_info_label.text = "Nama Room : %s" % nama

func _on_close_pressed():
	hide()

func _on_back_to_choice():
	room.hide()
	room_finder.hide()
	choice.show()

func _on_start_game_pressed():
	start_locally.rpc()
@rpc("any_peer", "call_local")
func start_locally():
	get_tree().change_scene_to_packed(world_loader)

