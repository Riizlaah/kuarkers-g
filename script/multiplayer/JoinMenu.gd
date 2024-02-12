extends Panel


func _on_join_pressed():
	get_parent().anim.play("joinmenu")
	await get_tree().create_timer(1).timeout
	hide()
	$Hbox2/LineEdit2.text = ""
	$Hbox2/LineEdit.text = ""
