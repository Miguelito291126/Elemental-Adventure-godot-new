extends HBoxContainer

var ip_Change = ""
var port_Change = ""
var last_seen: int

func _on_join_pressed() -> void:
	Network.port = port_Change.to_int() - 1
	Network.listener_port = Network.port + 1
	Network.broadcaster_port = Network.port - 1
	Network.ip = ip_Change
	Network.print_role("Joining " + ip_Change + ":" + port_Change)
	Network.Play_MultiplayerClient()
