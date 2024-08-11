extends MultiplayerSynchronizer

func _enter_tree():
	var id = multiplayer.get_unique_id()
	get_parent().uniqid = id
	get_parent().set_multiplayer_authority(id)
