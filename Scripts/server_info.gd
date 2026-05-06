extends HBoxContainer

var host_id: String
var port_Change: String
var ip_local_Change: String
var last_seen: int

func join_server() -> void:
	Network.port = port_Change.to_int()
	Network.steam_id = host_id.to_int()

	Network.print_role("Joining " + host_id + " at port " + str(Network.port))
	Network.Play_MultiplayerClient()
