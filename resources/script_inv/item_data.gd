extends Resource
class_name ItemData

@export var name : String = ""
@export var unique_name: String = ""
@export var icon : AtlasTexture
@export var stack: bool
@export var cooldown : float = 2.0
@export_category("3D")
@export var mesh3d: PackedScene
@export var pos: Vector3
@export var rot: Vector3
