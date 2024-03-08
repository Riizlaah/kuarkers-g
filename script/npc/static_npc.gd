extends BaseNPC
class_name StaticNPC

@export var color: Color

func _ready2():
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	$Armature/Skeleton3D/Cube.material_override = mat
	$Animation.play('walk')
