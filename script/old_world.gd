extends WorldTemplate

func _ready():
	set_world_spawn()
	get_parent().world_loaded()

func save_world():
	var npc_datas = {}
	#for npc in get_node("NPCs").get_children(): pass
	return npc_datas
