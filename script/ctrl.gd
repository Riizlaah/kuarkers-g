extends Control

@onready var pause_bg = $"../pause_bg"
@onready var charr = $".."
@onready var right = $Right
@onready var left = $Left

func _on_pause_pressed():
	pause_bg.visible = true
	visible = false
	charr.pause()
	pass


func _on_play_pressed():
	pause_bg.visible = false
	visible = true
	charr.pause()
	pass


func _on_keluar_pressed():
	get_tree().change_scene_to_file("res://scene/main.tscn")
	pass

