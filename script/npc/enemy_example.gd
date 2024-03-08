extends CharacterBody3D

const max_hp = 300
var hp = 300
@onready var label_3d = $Label3D

func _ready():
	update_hp()

func take_damage(dmg: int):
	hp = clamp(hp - dmg, 0, max_hp)
	update_hp()

func update_hp():
	label_3d.text = str(hp)
