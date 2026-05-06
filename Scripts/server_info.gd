extends HBoxContainer

var host_id: String
var port_Change: String
var ip_local_Change: String
var last_seen: int

func join_server() -> void:
	Network.steam_id = int(host_id)
	Network.port = int(port_Change)
	
	Network.print_role("Joining " + str(host_id) + " at port " + str(Network.port))
	Network.Play_MultiplayerClient()
