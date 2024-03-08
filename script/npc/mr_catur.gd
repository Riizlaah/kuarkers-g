extends BaseNPC

var dialogue = [
	{
		'name': 'index',
		'current': false,
		'text': 'Halo, ingin mendapat sesuatu?',
		'answer': [true, false],
		'yes': 'test'
	},{
		'name': 'test',
		'current': false,
		'text': 'Bunuh 5 kotak merah',
		'answer': [true, false],
		'require': 'kill-kotak_merah-5',
		'return': 'item-grenade-11'
	}
]

func _init():
	dialogues = dialogue
