extends MarginContainer

const lt_port = GManager.LT_PORT
const multicast_addr = GManager.MULTICAST_ADDR
const server_itf = preload("res://scene/server_itf.tscn")

@onready var server_lan_list = $Hbox/Vbox/Scont/Vbox
@onready var main_menu = $"../../../.."
@onready var direct_join_window: Confirm = $"../../direct_join_window"
@onready var game_addr: LineEdit = $"../../direct_join_window/Confirm/Vbox/game_addr"
@onready var hint_lb: Label = $"../../direct_join_window/Confirm/Vbox/Label"
@onready var direct_join_confirm: Button = $"../../direct_join_window/Confirm/Vbox/Hbox/Button2"
@onready var panel_2: Panel = $"../../../../Panel2"

var lt_peer := PacketPeerUDP.new()
var iface_name: String

func _ready():
	iface_name = IP.get_local_interfaces()[0].name
	var label = $"../../../../Label2"
	if lt_peer.bind(lt_port) != OK: label.show()
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if !OS.is_debug_build(): lt_peer.join_multicast_group(multicast_addr, iface_name)

func _process(_delta):
	if lt_peer.get_available_packet_count() > 0: process_packet()

func process_packet():
	var data = JSON.parse_string(lt_peer.get_packet().get_string_from_utf8())
	if lt_peer.get_packet_error() != OK: return
	if typeof(data) != TYPE_DICTIONARY: return
	if !data.has('server_ip'): return
	var node_name = data.server_ip.replace('.', '_')
	var server_node = server_lan_list.get_node_or_null(node_name)
	if is_instance_valid(server_node):
		server_node.set_info_player(data.player_count)
	else:
		var new_server = server_itf.instantiate()
		new_server.name = node_name
		server_lan_list.add_child(new_server)
		new_server.load_data(data)
		new_server.join_server.connect(join_server)

func join_server(ip: String, port: int):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		multiplayer.multiplayer_peer = null
		OS.alert("Gagal bergabung dengan server", "Peringatan")
		get_tree().reload_current_scene()
		return
	multiplayer.multiplayer_peer = peer
	print(err, multiplayer.get_unique_id())

func connection_failed():
	print('nope')
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()

func connected_to_server():
	print('connected')
	main_menu.hide()
	GManager.send_player_info.rpc_id(1, multiplayer.get_unique_id(), Settings.player_uuid, Settings.player_name, Settings.player_color.to_html())

func _on_direct_join_confirmed() -> void:
	var game_address = game_addr.text.split(";", false)
	join_server(game_address[0], game_address[1].to_int())
	get_node("ConnectionTimedOut").start()
	panel_2.show()

func _on_direct_join_pressed() -> void:
	direct_join_window.show()

func _on_game_addr_text_changed(new_text: String) -> void:
	var regex = RegEx.create_from_string("^\\d+(\\.\\d+){3};\\d{4,5}$")
	if is_instance_valid(regex.search(new_text)):
		hint_lb.text = "Alamat game sudah valid."
		hint_lb.add_theme_color_override("font_color", Color.GREEN)
		direct_join_confirm.disabled = false
	else:
		hint_lb.text = "Alamat game belum valid.\nContoh: 127.0.0.1;25786"
		hint_lb.add_theme_color_override("font_color", Color.RED)
		direct_join_confirm.disabled = true

func _on_connection_timed_out() -> void:
	get_node("ConnectionTimedOut").stop()
	if GManager.connected_to_server == true: return
	panel_2.get_node("Label").text = "Koneksi Terputus\nMemuat ulang game"
	await get_tree().create_timer(2).timeout
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()
