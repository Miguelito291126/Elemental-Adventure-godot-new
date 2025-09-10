extends HBoxContainer

var ip_Change = ""
var port_Change = ""

func _on_join_pressed() -> void:
	Network.port = port_Change.to_int() - 1
	Network.ip = ip_Change
	print("Joining " + ip_Change + ":" + port_Change)
	Network.Play_MultiplayerClient()
