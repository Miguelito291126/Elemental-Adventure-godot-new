extends HBoxContainer

var ip_Change = ""
var port_Change = ""

func _on_join_pressed() -> void:
	GameController.port = int(port_Change)
	GameController.ip = ip_Change
	print("Joining " + ip_Change + ":" + port_Change)
	GameController.Play_MultiplayerClient()
