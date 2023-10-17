extends CharacterBody3D

@onready var LabelHP = $Label3D

const maxHP = 100
var currHP: int = maxHP

func _ready():
	#await get_tree().create_timer(0.1).timeout
	LabelHP.text = str(currHP)
	pass

func updateHP():
	LabelHP.text = str(currHP)

func takeDamage(damage: int):
	currHP = clamp(currHP - damage, 0, maxHP)
	if currHP == 0:
		currHP = maxHP
	updateHP()
func healHP(heal):
	currHP = clamp(currHP + heal, 0, 100)
	updateHP()

