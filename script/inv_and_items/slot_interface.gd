extends PanelContainer

signal slot_clicked(idx: int)

var active: bool
@onready var texture = $MarginContainer/TextureRect2
@onready var stack_count = $MarginContainer/Label
@onready var active_texr = $TextureRect

func _ready():
	if active:
		active_texr.show()
		return
	active_texr.hide()

func _on_slot_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		slot_clicked.emit(get_index())

func set_slot_d(slot_d: SlotData):
	var data = slot_d.item_data
	texture.texture = data.icon
	if slot_d.stack_count > 1:
		stack_count.text = "%s" % slot_d.stack_count
		stack_count.show()
		return
	stack_count.hide()
