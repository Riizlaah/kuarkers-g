extends Resource
class_name itemData

@export var name : String = ""
@export var icon : AtlasTexture
@export var stack : bool
@export var onhand_texture : AtlasTexture
@export var onhand_pos : Vector3 = Vector3(0,-0.15,0.1)
@export var onhand_rot : Vector3 = Vector3(0, -90, 90)
@export var onhand_scale : float = 0.5
@export var muzzle_pos: Vector3 = Vector3.ZERO
@export var type: ItemType

