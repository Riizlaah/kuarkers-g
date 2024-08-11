extends Panel

const output_label = preload("res://scene/output_label.tscn")

var chat_manager: ChatManager

@onready var hbox = $Hbox
@onready var vbox = $Vbox/SCont/Vbox
@onready var line_edit = $Hbox/LineEdit
@onready var s_cont = $Vbox/SCont

var old_hbox_pos: int

func receive_msg(msg: String, color: Color = Color.WHITE):
	var lb = output_label.instantiate()
	lb.text = msg
	lb.modulate = color
	vbox.add_child(lb)
	await RenderingServer.frame_post_draw
	s_cont.scroll_vertical = max(0, s_cont.get_v_scroll_bar().max_value)

func clear():
	for i in vbox.get_children(): i.queue_free()

func _ready():
	receive_msg("selamat datang!... \nketik =ls_cmd di bawah untuk mengetahui list perintah yang ada\ncatatan: tambahkan '=' di awal untuk mengeksekusi perintah,\nmisal: \n  =lsp     maka akan mengeluarkan list pemain\nketik :clear untuk menghilangkan semua pesan dan log", Color.DARK_GRAY)
	old_hbox_pos = roundi(hbox.position.y)

func _on_line_edit_clicked():
	if Settings.os_name != 'Android': return
	hbox.position.y -= (size.y * 0.5) + hbox.size.y

func _on_line_edit_focus_exited():
	hbox.position.y = old_hbox_pos

func _on_line_edit_text_submitted(new_text: String):
	if new_text == ":clear":
		clear()
		hbox.position.y = old_hbox_pos
		line_edit.text = ""
		return
	var output = ""
	if new_text.begins_with("="):
		output = chat_manager.send_cmd(new_text.trim_prefix("="), get_parent().get_parent().player_name)
	else:
		chat_manager.send_msg(new_text, get_parent().get_parent().player_name)
	if !output.is_empty(): receive_msg(output, Color.WEB_GRAY)
	hbox.position.y = old_hbox_pos
	line_edit.text = ""

func _on_back_pressed():
	get_parent().hide()
	get_parent().get_parent().get_node("Layer1").show()

func _on_s_cont_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed(): _on_line_edit_focus_exited()

func _on_send_pressed():
	_on_line_edit_text_submitted(line_edit.text)
