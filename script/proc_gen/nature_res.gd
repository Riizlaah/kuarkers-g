class_name NatureRes
extends Node3D

enum ResType {
	TREE,
	STONE,
	GRASS
}

var res_type: ResType
var drop_count := 0:
	set(v):
		drop_count = v
		if v == 0: drop_count = randi_range(1, 7)
var destr_phase := -1:
	set(v):
		destr_phase = v
		if v == -1: destr_phase = 5
@onready var tree_nodes = [$Tree1, $Tree2, $Tree3]
@onready var stone_nodes = [$Stone1, $Stone2, $Stone3]
@onready var grass_nodes = [$Grass, $Grass2, $Grass3]

func _ready():
	var res_nodes := []
	var unused := []
	match res_type:
		ResType.TREE:
			res_nodes = tree_nodes
			unused.append_array(grass_nodes)
			unused.append_array(stone_nodes)
		ResType.STONE:
			res_nodes = stone_nodes
			unused.append_array(grass_nodes)
			unused.append_array(tree_nodes)
		ResType.GRASS:
			res_nodes = grass_nodes
			unused.append_array(stone_nodes)
			unused.append_array(tree_nodes)
		_: pass
	for node in unused: node.queue_free()
	var selected: int = 0
	if drop_count <= 3: pass
	elif drop_count <= 5: selected = 1
	else: selected = 2
	var selected_node: Node3D
	for idx in res_nodes.size():
		if idx == selected:
			selected_node = res_nodes[idx]
			continue
		res_nodes[idx].queue_free()
	selected_node.rotation_degrees.y += randi_range(-8, 8) * 45
