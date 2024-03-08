extends Button

signal join_room(ip: String, port: int, rn: String)

var ip: String
var port: int
var rn: String

func _pressed():
	join_room.emit(ip, port, rn)
