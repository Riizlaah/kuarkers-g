extends Button

signal joinGame(ip: String)
var ip = ""

func _on_pressed():
	joinGame.emit(ip)
