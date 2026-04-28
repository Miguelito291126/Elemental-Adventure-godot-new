extends HBoxContainer

var ip_public_Change: String
var port_Change: String
var ip_local_Change: String
var last_seen: int

func join_server() -> void:
	Network.port = port_Change.to_int()
	Network.ip = ip_public_Change

	if ip_public_Change == Network.PublicIp:
		Network.ip = ip_local_Change

	
	Network.print_role("Joining " + ip_public_Change + ":" + port_Change)
	Network.Play_MultiplayerClient()
