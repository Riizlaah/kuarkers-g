extends Control

const chat_text = preload("res://resources/cmd/chat_text.tscn")

@onready var text_edit = $Panel/HBoxContainer/TextEdit
@onready var HBox = $Panel/HBoxContainer
@onready var Vbox = $Panel/ScrollContainer/VBoxContainer
@onready var panel = $Panel

@export var chat_btn : TextureButton

var default_input_pos := 665


func _on_text_edit_text_submit(new_text: String):
	#if new_text.contains("\n"):
	var text = parse_text(new_text)
	var label_s = chat_text.instantiate()
	label_s.text = text
	Vbox.add_child(label_s)
	text_edit.clear()
	await get_tree().create_timer(0.3).timeout
	HBox.position.y = default_input_pos

func _unhandled_input(_event):
	if not text_edit.has_focus():
		HBox.position.y = default_input_pos
	pass

func _on_text_edit_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		await get_tree().create_timer(0.3).timeout
		var keyboard_h = DisplayServer.virtual_keyboard_get_height()
		var text_edit_pos = size.y - keyboard_h - 55
		HBox.position.y = text_edit_pos

func _on_panel_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		HBox.position.y = default_input_pos
		text_edit.deselect()
		DisplayServer.virtual_keyboard_hide()

func parse_text(text: String):
	return "[" + Settings.p_name + "]" + " " + text

func _on_close_pressed():
	hide()
	chat_btn.show()


