extends HBoxContainer

var ip_Change = ""
var port_Change = ""

func _on_join_pressed() -> void:
	GameController.port = port_Change.to_int() - 1
	GameController.ip = ip_Change
	print("Joining " + ip_Change + ":" + port_Change)
	GameController.Play_MultiplayerClient()
