extends Control

@export var bg_textures: Array[CompressedTexture2D]

@onready var play_menu = $Mcont/PlayMenu
@onready var settings_menu = $Mcont/SettingsMenu
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	get_node("TextureRect").texture = bg_textures.pick_random()

func _on_play():
	play_menu.show()

func _on_quit_pressed():
	get_tree().quit()

func _on_setting():
	settings_menu.show()

func _on_create_room():
	$Mcont/Vbox/Hbox/quit.hide()
	$Mcont/Vbox/Hbox/setting.hide()
	$Mcont/Vbox/Hbox/quick_host.hide()

func _quit_room():
	$Mcont/Vbox/Hbox/quit.show()
	$Mcont/Vbox/Hbox/setting.show()
	$Mcont/Vbox/Hbox/quick_host.show()
