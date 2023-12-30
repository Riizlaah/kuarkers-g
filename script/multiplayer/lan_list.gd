extends Button

signal joinGame(ip: String, port: int)
var ip: String
var port: int

func _on_pressed():
	joinGame.emit(ip, port)
