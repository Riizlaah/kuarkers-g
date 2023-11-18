extends Node

func write_deb(text: String):
	var file = FileAccess.open("res://resources/debug.txt", FileAccess.WRITE)
	file.store_string(text)
