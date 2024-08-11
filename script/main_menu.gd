extends Control

@export var bg_textures: Array[CompressedTexture2D]

@onready var play_menu = $Mcont/PlayMenu
@onready var settings_menu = $Mcont/SettingsMenu
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var game_info = $Mcont/SettingsMenu/TabCont/Info/game_info
@onready var connection_timed_out: Timer = $Mcont/PlayMenu/TabContainer/Multiplayer/ConnectionTimedOut
func _ready():
	GManager.main_menu = self
	Settings.bg_img = bg_textures.pick_random()
	get_node("TextureRect").texture = Settings.bg_img
	game_info.text = create_info()

func create_info() -> String:
	var text := ""
	var renderer := Settings.renderer
	var os = Settings.os_name
	text += "Renderer : " + renderer
	text += "\nOS : " + os
	return text

func stop_connection_timer():
	connection_timed_out.stop()

func _on_play():
	play_menu.show()

func _on_quit_pressed():
	get_tree().quit()

func _on_setting():
	settings_menu.show()

func stop_main_music():
	audio.stop()
