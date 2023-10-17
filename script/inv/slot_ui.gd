extends PanelContainer

signal slotClicked(index: int, btn: int)

@onready var texture = $MarginContainer/TextureRect
@onready var lb = $Label
@onready var active : TextureRect = $TextureRect



func set_slotD(slotD: slotData):
	var data = slotD.item_data
	texture.texture = data.icon
	
	if slotD.quantity > 1:
		lb.text = "x%s" % slotD.quantity
		lb.show()
	else:
		lb.hide()
	pass

func activate(slotD: slotData):
	if slotD.active == true:
		active.show()
	else:
		active.hide()

func _on_gui_input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.is_pressed():
			slotClicked.emit(get_index())
	pass # Replace with function body.
