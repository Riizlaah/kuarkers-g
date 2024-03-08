extends Node


const worlds = {
	'mountain': preload("res://scene/worlds/mountain.tscn")
}

var players : Dictionary = {}
var curr_world = worlds['mountain']
