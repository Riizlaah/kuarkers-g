extends Node

#signal new_player_connected(id: int)

var limited_worlds = {
	1: preload("res://scene/proc_gen/inf_terrain.tscn"),
	2: preload("res://scene/worlds/mountain.tscn"),
	3: preload("res://scene/worlds/city.tscn")
}
const world_loader = preload("res://scene/world_loader.tscn")
const MULTICAST_ADDR = "224.0.0.1"
const BR_PORT = 8082
const LT_PORT = 8083

var players := {}
var dupl_name := {}
var world_data: Dictionary
var new_world := false
var world: WorldLoader
var main_menu: Control
var server_data := {}
var game_addr := ""
var connected_to_server := false:
	set(val):
		connected_to_server = val
		if val == true:
			main_menu.stop_connection_timer()

@rpc("any_peer")
func send_player_info(id, uuid, player_name, color):
	if !GManager.players.has(id):
		GManager.players[id] = {'uuid' : uuid, 'name': player_name, 'color': color}
		world.player_data_added(id)
	if multiplayer.is_server():
		players = _make_unique_name()
		if id != 1: server_correct.rpc_id(id)
		for i in GManager.players:
			var player = GManager.players[i]
			send_player_info.rpc(i, player.uuid, player.name, player.color)

@rpc("any_peer")
func send_game_addr(addr):
	game_addr = addr

func _make_unique_name():
	var dupl = []
	var players2 = players
	for id in players2:
		var p_name = players2[id].name
		if dupl.has(p_name):
			if dupl_name.has(p_name): dupl_name[p_name] += 1
			else: dupl_name[p_name] = 0
			if dupl_name[p_name] > 0: p_name = "%s(%d)" % [p_name, dupl_name[p_name]]
			players2[id].name = p_name
		else: dupl.append(p_name)
	return players2

@rpc("any_peer")
func spawn_world():
	if !multiplayer.is_server(): return
	main_menu.get_node("Level").add_child(world_loader.instantiate())
	main_menu.hide()

func get_player(id: int) -> Node: return world.players.get_node_or_null(str(id))

func stop_main_music():
	main_menu.stop_main_music()

@rpc("any_peer")
func server_correct(): connected_to_server = true
