class_name Confirm
extends ColorRect

@onready var label = $Confirm/Vbox/Label

signal confirmed

func update_text(text: String):
	label.text = "Anda yakin ingin menghapus dunia '%s'?" % text

func _on_confirmed():
	confirmed.emit()
	hide()

func _on_cancel():
	hide()
