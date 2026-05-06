extends HBoxContainer

var host_id: String
var lobby_id: String
var last_seen: int

func join_server() -> void:
	Network.join_steam_lobby(int(lobby_id))
