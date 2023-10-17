extends Node

var ResItemArr 

func _ready():
	ResItemArr = [
		preload("res://resources/items/akm_i.tres"),
		preload("res://resources/items/ammo_i.tres"),
		preload("res://resources/items/arit_i.tres"),
		preload("res://resources/items/awm_i.tres"),
		load("res://resources/items/botol_i.tres"),
		load("res://resources/items/donat_i.tres"),
		load("res://resources/items/golok_i.tres"),
		load("res://resources/items/grenade_i.tres"),
		load("res://resources/items/kapak_i.tres"),
		load("res://resources/items/med_i.tres"),
		preload("res://resources/items/mp5_i.tres"),
		preload("res://resources/items/pistol_i.tres"),
		preload("res://resources/items/rocket_i.tres"),
		preload("res://resources/items/rpg_i.tres")
	]
func write_deb(text: String):
	var file = FileAccess.open("res://resources/debug.txt", FileAccess.WRITE)
	file.store_string(text)
