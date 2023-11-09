extends Resource
class_name BaseCMD


func parse(text: String):
	if text.begins_with("="):
		pass#exec(text.replace("=", ""))
	else:
		sendChat(text)


func sendChat(text: String):
	print("<" + Settings.p_name + ">" + " " + text)
	pass


