extends HBoxContainer

var Ip_Change = ""
var Port_Change = ""

func _on_join_pressed() -> void:
	GameController.port = int(Port_Change)
	GameController.ip = Ip_Change
	print("Joining " + Ip_Change + ":" + Port_Change)
	GameController.Play_MultiplayerClient()
