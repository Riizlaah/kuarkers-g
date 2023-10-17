extends StaticBody3D
class_name chest

@export var inv_d : invData

func sMSlot(inv_dd: invData):
	inv_d = inv_dd
	if inv_dd.slotDatas.size() > 8:
		var fArr = inv_dd.slotDatas.slice(8, inv_dd.slotDatas.size())
		inv_d.slotDatas = [fArr]
	pass

func player_interact():
	return inv_d
