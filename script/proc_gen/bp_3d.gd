class_name BasePlaceable3D
extends StaticBody3D

@onready var mesh_3d = $Mesh
var next_remove: Variant = null

enum StoneType {
	none = -1,
	first = 0,
	second = 1,
	third = 2
}

@export_category("Placeable3D")
@export var stone_type: StoneType
#@export var tree:  = null
#@export var type: GManager.ObjType
#@export var type: GManager.....

func _ready():
	set_process(false)
	set_physics_process(false)

func _exit_tree():
	if is_instance_valid(next_remove): next_remove.queue_free()
	#else: if is_instance_valid(tree): tree.check_wood_count()
	##TODO IMPLEMENTASI DROP/PICKUP ITEMget_node("/root/INFTerrain").add_child(GManager.objects[drop])
