extends Node

const DEFAULT_NAME = "Heker"

enum SkyGraphics {
	Low,
	Medium,
	High
}

var player_name := DEFAULT_NAME
var senv := 10.0
var player_color := Color.WHITE
var view_dist := 200
var scale_3d := 1.0
var sky_graphic : SkyGraphics = SkyGraphics.Low
