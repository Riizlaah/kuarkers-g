extends CharacterBody3D
class_name BaseNPC

signal killed_by(player_name: String)

enum npc_type {
	Sabar,
	Netral,
	Pemarah
}

@export var dialogues : Array[Dictionary] = [{}]
@export var can_att := false
@export var can_walk := false
@export var using_path := false
@export var invincible := true
@export var type: npc_type = npc_type.Sabar
@export var speed := 10
@export var wandering_range := 20
@export var max_hp := 200.0
@export var heal_hp := 50
@export var path: Path3D
@export var curr_point := 0

var timer: Timer
var is_running_quest := false
var target_pos := Vector3.ZERO
var target_node: Node3D
var hp: float
var points: int
var points_pos : PackedVector3Array = []
var gravity := 10.0
var dir := Vector3.ZERO

@onready var world_loader = GManager.world

func _enter_tree():
	set_multiplayer_authority(1)
	var timer1 = Timer.new()
	timer1.name = "timer"
	timer1.wait_time = 2
	add_child(timer1)
	timer1.timeout.connect(heal)

func _ready():
	set_collision_layer_value(1, false)
	set_collision_layer_value(6, true)
	hp = max_hp
	timer = get_node("timer")
	_ready2()
	if !is_instance_valid(path): return
	points = path.curve.point_count
	for point in points:
		var pos = path.global_position + (path.curve.get_point_position(point))
		points_pos.append(pos)
	#position = points_pos[curr_point]
	get_next_pos()

func _ready2():
	pass

func _physics_process(_delta):
	if !can_walk: return
	var is_reaching_point = global_position.round() == target_pos.round()
	if(!using_path and is_reaching_point == true):
		rand_target()
	elif(using_path == true and is_reaching_point == true):
		get_next_pos()
	else: pass
	if !is_on_floor(): dir.y -= gravity
	velocity = dir
	move_and_slide()
	velocity = velocity

func get_next_pos():
	curr_point = (curr_point + 1) % points
	target_pos = points_pos[curr_point]
	target_pos.y = global_position.y
	look_at(target_pos)
	dir = (target_pos - global_position).normalized()
	dir *= speed

func rand_target():
	if is_instance_valid(target_node):
		target_pos = target_node.position
		return
	target_pos = Vector3(randi_range(-wandering_range, wandering_range), global_position.y, randi_range(-wandering_range, wandering_range))
	look_at(target_pos)
	dir = (target_pos - global_position).normalized()
	dir *= speed

func take_damage(dmg: float, from: String):
	if invincible == true: return
	if type == npc_type.Netral or type == npc_type.Pemarah:
		target_node = world_loader.get_node(from)
		_sync_target()
	hp = clamp(hp - dmg, 0, max_hp)
	timer.start()
	_sync_hp()
	if hp == 0:
		killed_by.emit(from)
		queue_free()

func heal():
	if hp == max_hp: timer.stop()
	hp = clamp(hp + heal_hp, 0, max_hp)
	_sync_hp()

func interact(from):
	if dialogues.is_empty(): return
	if is_running_quest == true: return
	var dialog_idx = search_current_dialog()
	var dialog = dialogues[dialog_idx]
	world_loader.run_quest(from, dialog)#add: quest system
	_sync_status()

func search_current_dialog():
	for i in dialogues.size():
		if dialogues[i].current == false: continue
		return i
	return 0

func set_current_dialogue(idx: int):
	for i in dialogues.size():
		dialogues[i].current = false
	dialogues[idx].current = true

func exit_quest():
	for i in dialogues.size():
		dialogues[i].current = false
	is_running_quest = false
	_sync_status()

func _sync_hp():
	world_loader.sync_npc_hp.rpc(name, hp)

func _sync_target():
	world_loader.sync_npc_target.rpc(name, target_node.name)

func _sync_status():
	world_loader.sync_npc_quest_stat.rpc(name, is_running_quest)

func _sync_dialogues():
	world_loader.sync_npc_dialogues.rpc(name, dialogues)

func gen_uuid():
	randomize()
	const chars = "0123456789abcdef"
	var uuid = ""
	var segments = [2, 4, 8]
	for segment in segments:
		for i in segment:
			uuid += chars[randi() % chars.length()]
		uuid += "-"
	uuid = uuid.substr(0, uuid.length() - 1)
	return uuid
