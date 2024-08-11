@tool
extends MeshInstance3D

const center_offset = 0.5

@export_range(1, 100, 1) var resolution = 20
@export_range(20, 4000, 1) var terrain_size = 25
@export_range(5, 50, 1) var terrain_max_height = 8
@export var x_size = 20
@export var z_size = 20
@export var noise_offset = 0.5
@export var update = false
@export var clear_vert_vis = false
@export var noise : FastNoiseLite
var color: Color = Color.FOREST_GREEN

var min_height = 0
var max_height = 0

func _ready():
	gen_trn()

func gen_trn():
	var arr_mesh : ArrayMesh
	var surf_tool = SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in resolution + 1:
		for x in resolution + 1:
			var percent = Vector2(x, z) / resolution
			var point_on_mesh = Vector3((percent.x - center_offset), 0, (percent.y - center_offset))
			var vertex = point_on_mesh * terrain_size
			vertex.y = noise.get_noise_2d(vertex.x * noise_offset, vertex.z * noise_offset) * terrain_max_height
			if vertex.y < min_height and vertex.y != null: min_height = vertex.y
			if vertex.y > max_height and vertex.y != null: max_height = vertex.y
			var uv = Vector2()
			uv.x = percent.x
			uv.y = percent.y
			surf_tool.set_uv(uv)
			surf_tool.add_vertex(vertex)
	var vert = 0
	for z in resolution:
		for x in resolution:
			surf_tool.add_index(vert)
			surf_tool.add_index(vert + 1)
			surf_tool.add_index(vert + resolution + 1)
			surf_tool.add_index(vert + resolution + 1)
			surf_tool.add_index(vert + 1)
			surf_tool.add_index(vert + resolution + 2)
			vert += 1
	surf_tool.generate_normals()
	arr_mesh = surf_tool.commit()
	mesh = arr_mesh
	update_shader()

func update_shader():
	var mat = get_active_material(0)
	mat.set_shader_parameter("min_height", min_height)
	mat.set_shader_parameter("max_height", max_height)

func _process(_delta):
	if update:
		gen_trn()
		update = false
	if clear_vert_vis:
		for node in get_children():
			node.free()
			clear_vert_vis = false

func _gen_texture(color1: Color, path: String):
	var img = Image.create(32, 32, true, Image.FORMAT_RGB8)
	img.fill(color1)
	img.save_png("res://textures/" + path)
