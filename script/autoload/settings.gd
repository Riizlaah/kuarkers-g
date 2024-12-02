extends Node

const DEFAULT_NAME = "Heker"
const DEFAULT_SENV = 100.0
const DEFAULT_COLOR = Color.WHITE
const DEFAULT_SKY = SkyGraphics.Low
const DEFAULT_SCALE3D = 1.0
const DEFAULT_RENDER_DIST = 2
const renderer_alias = {
	'gl_compatibility': 'OpenGL',
	'mobile': 'Vulkan',
	'forward_plus': 'Vulkan'
}
const CHUNK_SIZE = 32
const lods = [4, 8, 16]
const lods_dist = [8192, 4096, 1024]
const GAME_VERSION := "1.3.1"

enum SkyGraphics {
	Low,
	Medium,
	High
}

var player_uuid: String
var player_name := DEFAULT_NAME
var senv := 10.0
var player_color := Color.WHITE
var scale_3d := DEFAULT_SCALE3D
var sky_graphic : SkyGraphics = SkyGraphics.Low
var render_distance := DEFAULT_RENDER_DIST

var bg_img: Texture2D
var os_name := OS.get_name():
	set(val):
		os_name = val
		if val == "Android" or val == "iOS": is_desktop = false
		else: is_desktop = true
var renderer := ""
var is_desktop := false

func gen_uuid() -> String:
	randomize()
	const chars = "0123456789abcdef"
	var uuid = ""
	var segments = [8, 4, 4, 4, 12]
	for segment in segments:
		for i in segment:
			uuid += chars[randi() % chars.length()]
		uuid += "-"
	uuid = uuid.substr(0, uuid.length() - 1)
	return uuid

func _enter_tree():
	var uuid := FileAccess.get_file_as_string("user://uuid")
	if uuid.is_empty(): uuid = gen_uuid()
	player_uuid = uuid
	var uuid_file := FileAccess.open("user://uuid", FileAccess.WRITE)
	uuid_file.store_string("")
	uuid_file.store_string(uuid)
	uuid_file.close()
	if os_name == "Android": renderer = renderer_alias[ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile")]
	else: renderer = renderer_alias[ProjectSettings.get_setting("rendering/renderer/rendering_method")]
