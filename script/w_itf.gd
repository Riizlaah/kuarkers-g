extends Button

signal join_server(ip: String, port: int)

@onready var world_name = $Mcont/Hbox/Vbox/Label
@onready var host_name = $Mcont/Hbox/Vbox/Label2
@onready var version = $Mcont/Hbox/Vbox2/Label
@onready var info_player = $Mcont/Hbox/Vbox2/Label2

var server_ip: String
var server_port: int
var max_players_before: int

func load_data(data: Dictionary):
	if !data.has('server_ip') or !data.has('server_port') or !data.has('world_name') or !data.has('host_name') \
	or !data.has('player_count') or !data.has('max_players'):
		queue_free()
		return
	server_ip = data.server_ip
	server_port = data.server_port
	world_name.text = data.world_name
	host_name.text = data.host_name
	version.text = data.version
	max_players_before = data.max_players
	info_player.text = "{0} / {1} pemain".format([data.player_count, data.max_players])

func set_info_player(player_count: int, max_players: int = 0):
	if max_players < 1: max_players = max_players_before
	info_player.text = "{0} / {1} pemain".format([player_count, max_players])
	max_players_before = max_players

func _pressed():
	join_server.emit(server_ip, server_port)
