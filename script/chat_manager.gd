extends Node
class_name ChatManager

var world_node : Node3D
var curr_player_name := ""

const commands = {
	'help': " <nama-perintah> : Menampilkan bantuan tentang `nama-perintah`",
	'lsp': " : menampilkan pemain yang ada di server ini",
	'ls_cmd': " : menampilkan semua perintah yang ada",
	'time': " <nama-waktu> : mengatur waktu ke `nama-waktu`",
	'tp': " <posisi: (x y z)> : teleportasi ke `posisi`",
	'tpa': " <nama-pemain> : teleportasi ke `pemain` berdasarkan `nama-pemain`"
}

const example = {
	'help' : " =help time     ....(mengeluarkan bantuan untuk perintah `time`)",
	'lsp': " =lsp     ....(menampilkan semua pemain yang ada di server saat ini)",
	'ls_cmd': " =ls_cmd     ....(menampilkan semua perintah yang ada)",
	'time': " =time pagi     ....(mengatur waktu menjadi pagi)",
	'tp': " =tp 0 100 90     ....(teleportasi ke koordinat vector3(x: 0, y: 100, z: 90))",
	'tpa': " =tpa Heker     ....(teleportasi ke `Heker`)"
}

const times = {
	'pagi': 0,
	'siang': 1,
	'sore': 2,
	'malam': 3,
	'tengah_malam': 4
}

func _enter_tree():
	set_multiplayer_authority(1)

func send_msg(msg: String, player_name: String):
	msg = "(" + player_name + ") " + msg
	world_node.send_msg.rpc(msg)

func send_cmd(command: String, player_name: String):
	curr_player_name = player_name
	var raw = command.split(" ")
	var func_name = raw[0]
	raw.remove_at(0)
	if !has_method(func_name): return 'perintah tidak eksis : ' + func_name
	return callv(func_name, raw)

func tp(to_x: String, to_y: String, to_z: String):
	if !to_x.is_valid_float() or !to_y.is_valid_float() or !to_z.is_valid_float(): return 'posisi tidak valid : (' + to_x + ',' + to_y + ',' + to_z + ')'
	var pos = Vector3(to_x.to_float(), to_z.to_float(), to_y.to_float())
	world_node.players_node[curr_player_name].position = pos
	return curr_player_name + " tp to: "+str(pos)

func tpa(who: String):
	if !world_node.players_node.has(who): return 'pemain tidak eksis : ' + who
	var pos = world_node.players_node[who].global_position
	world_node.players_node[curr_player_name].position = pos
	return curr_player_name + " tpa to: "+who

func time(tname: String):
	if !times.has(tname): return 'nama waktu tidak valid !, nama valid : pagi , siang , sore , malam , tengah_malam'
	world_node._change_time.rpc(times[tname])
	return 'waktu diatur menjadi ' + tname

func lsp():
	var players = "Pemain :\n"
	var i = 0
	for player in world_node.players_node:
		i += 1
		players += str(i) + '. ' + player + "\n"
	players += "jumlah pemain = " + str(i)
	return players

func ls_cmd():
	var o_cmds = ''
	for cmd in commands:
		o_cmds += cmd + commands[cmd] + "\n"
	return o_cmds

func help(cmd_name: String):
	if !commands.has(cmd_name): return 'perintah tidak eksis : ' + cmd_name
	return cmd_name + commands[cmd_name] + ', \ncontoh : \n' + example[cmd_name]
