extends MarginContainer

const allowed_chars = "0123456789abcdefghijklmnopqrstuvwxyz"
const w_itf = preload("res://scene/world_itf.tscn")
const dummy_world_texture = preload("res://resources/texture/main-menu/dummy-world.png")
@onready var mkworld_view = $"../../mkworld_view"
@onready var wmenu_lb = $"../../mkworld_view/Vbox/Panel/Hbox/Label"
@onready var world_name = $"../../mkworld_view/Vbox/Scont/Hbox/Vbox/world_name"
@onready var world_seed = $"../../mkworld_view/Vbox/Scont/Hbox/Vbox/Hbox/world_seed"
@onready var world_gm = $"../../mkworld_view/Vbox/Scont/Hbox/Vbox/world_gm"
@onready var world_type = $"../../mkworld_view/Vbox/Scont/Hbox/Vbox/world_type"
@onready var close_playmenu = $"../../Close"
@onready var server_manager = $"../Multiplayer"
@onready var gcont = $Vbox/Scont/Gcont
@onready var world_menu = $Vbox/Hbox/Hbox
@onready var world_tmb = $"../../mkworld_view/Vbox/Scont/Hbox/Vbox2/texture"
@onready var continue_btn = $"../../mkworld_view/Vbox/Panel/Hbox/continue"
@onready var rand_seed = $"../../mkworld_view/Vbox/Scont/Hbox/Vbox/Hbox/rand_seed"
@onready var del_confirmation = $"../../../../del_confirmation"
@onready var tmb_info = $"../../mkworld_view/Vbox/Scont/Hbox/Vbox2/Label"

var selected_world: WorldItf:
	set(val):
		selected_world = val
		if is_instance_valid(selected_world): toggle_world_menu(true)
		else: toggle_world_menu(false)

var server_ip := ""
var server_port: int

func _ready():
	server_ip = IP.get_local_addresses()[0]
	server_port = randi_range(8085, 60000)
	GManager.game_addr = server_ip + ";" + str(server_port)
	load_worlds()
	_rand_seed()

func load_worlds():
	for node in gcont.get_children(): node.queue_free()
	var datas = FileSystem.get_worlds_data()
	for data in datas:
		var world = w_itf.instantiate()
		gcont.add_child(world)
		world.load_data(data)
		world.world_clicked.connect(world_clicked)

func world_clicked(idx: int):
	for node in gcont.get_children(): node.selected = false
	var world_node = gcont.get_child(idx)
	world_node.selected = true
	selected_world = world_node

func toggle_world_menu(toggled_on: bool):
	if toggled_on: world_menu.show()
	else: world_menu.hide()

func unselect_world():
	if !is_instance_valid(selected_world): return
	selected_world.selected = false
	selected_world = null

func _on_mkworld_pressed():
	show_mkworld_menu(false)

func show_mkworld_menu(edit_mode: bool):
	if !edit_mode:
		_on_back_to_wman_pressed()
		world_name.text = "Dunia."
		_rand_seed()
	mkworld_view.show()
	close_playmenu.hide()

func _on_back_to_wman_pressed():
	wmenu_lb.text = "Buat Dunia..."
	continue_btn.text = "Buat Dunia"
	world_seed.show()
	rand_seed.show()
	world_gm.disabled = false
	world_gm.select(0)
	world_type.disabled = false
	world_type.select(0)
	world_seed.editable = true
	world_tmb.texture = dummy_world_texture
	tmb_info.show()
	mkworld_view.hide()
	close_playmenu.show()

func _on_continue_mkworld_pressed():
	if is_instance_valid(selected_world) and continue_btn.text == "Simpan":
		save_edited_world()
		return
	if !validate(): return
	var seed_text = world_seed.text
	var data = {
		'name': world_name.text,
		'seed': seed_text.to_int() if seed_text.is_valid_int() else seed_text.hash(),
		'gamemode': world_gm.selected,
		'type': world_type.selected,
		'save_dir': str((randf() * randf_range(1, 2)) + randf()).sha1_text().substr(0, 12)
	}
	GManager.new_world = true
	GManager.world_data = data
	start_server(world_name.text)
	#get_tree().change_scene_to_packed(GManager.world_loader)

func validate() -> bool:
	if world_name.text.is_empty():
		OS.alert("Nama Dunia tidak boleh kosong", "Peringatan")
		return false
	if world_name.text.begins_with(" "):
		OS.alert("Nama dunia tidak boleh berawalan spasi", "Peringatan")
		return false
	var explode = world_seed.text.split()
	for c in explode:
		if c in allowed_chars: continue
		OS.alert("Seed mengandung karakter yang tidak diperbolehkan: "+c, "Peringatan")
		return false
	return true

func _rand_seed(): world_seed.text = str(randf()).sha1_text().sha1_text().substr(0, 8)

func _on_close_pressed():
	unselect_world()
	get_parent().get_parent().hide()
	load_worlds()

func _on_tab_clicked(_tab):
	unselect_world()

func _on_mcont_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		if !get_global_rect().has_point(event.position): unselect_world()

func _on_play_world():
	GManager.new_world = false
	GManager.world_data = selected_world.world_data
	start_server(selected_world.world_data.name)
	#get_tree().change_scene_to_packed(GManager.world_loader)

func _on_edit_world():
	var w_data = selected_world.world_data
	wmenu_lb.text = "Edit Dunia..."
	continue_btn.text = "Simpan"
	world_tmb.texture = w_data.tmb
	tmb_info.hide()
	world_name.text = w_data.name
	world_seed.text = str(w_data.seed)
	world_seed.editable = false
	rand_seed.hide()
	world_gm.select(w_data.gamemode)
	world_type.select(w_data.type)
	world_type.disabled = true
	show_mkworld_menu(true)

func save_edited_world():
	var w_data = selected_world.world_data
	if !validate(): return
	w_data.name = world_name.text
	w_data.gamemode = world_gm.selected
	FileSystem.mkdir('world')
	FileSystem.ch_dir('world')
	FileSystem.write(w_data.save_dir + "/world.dat", w_data)
	FileSystem.chdir_base()
	world_tmb.texture = dummy_world_texture
	tmb_info.show()
	_on_back_to_wman_pressed()
	load_worlds()
	selected_world = null

func _on_delete_confirmed():
	if !is_instance_valid(selected_world): return
	FileSystem.mkdir('world')
	FileSystem.ch_dir('world')
	FileSystem.rm(selected_world.world_data.save_dir)
	gcont.remove_child(selected_world)
	selected_world = null
	FileSystem.chdir_base()

func _on_del_world():
	del_confirmation.update_text(selected_world.world_data.name)
	del_confirmation.show()

func start_server(w_name: String):
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(server_port) != OK:
		OS.alert("Gagal membuat server", "Peringatan")
		get_tree().reload_current_scene()
		return
	multiplayer.multiplayer_peer = peer
	GManager.server_data = {
		'server_ip': server_ip,
		'server_port': server_port,
		'world_name': w_name,
		'host_name': Settings.player_name,
		'version': Settings.GAME_VERSION,
		'max_players': 10,
		'player_count': 0
	}
	GManager.call_deferred("spawn_world")
