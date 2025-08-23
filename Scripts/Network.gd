extends Node

var port = 9999
var lisenerport = port + 1
var broadcasterport = port + 2
var ip = "127.0.0.1"
var broadcasteripadress = "255.255.255.255"
var username = "Player"
var connected_ids: Array = []
var connection_count = 0
var is_networking = false
var is_host = false
var multiplayer_peer_Enet = ENetMultiplayerPeer.new()
var multiplayer_peer_Enet_host
var multiplayer_peer_Enet_peers
var multiplayer_peer_Enet_peer
var multiplayer_peer_websocker = WebSocketMultiplayerPeer.new()
var multiplayer_peer_websocker_peer

func joinbyip(ip_value, port_value):
	if OS.get_name() == "Web":
		var error = multiplayer_peer_websocker.create_client("ws://" + ip_value + ":" + str(port_value))
		if error == OK:
			multiplayer.multiplayer_peer = multiplayer_peer_websocker
			multiplayer_peer_websocker.handshake_timeout = 60.0
			if not multiplayer.is_server():
				is_networking = true
				is_host = false
				get_parent().get_node("Game/Main Menu").hide()
				get_parent().get_node("Game/Game_Controls").show()
				print("Loading level...")
				UnloadScene.unload_scene(get_parent().get_node("Game/Chose_Character"))
		else:
			push_error("Error creating client: ", str(error))
	else:
		var error = multiplayer_peer_Enet.create_client(ip, port)
		if error == OK:
			multiplayer.multiplayer_peer = multiplayer_peer_Enet
			multiplayer_peer_Enet_host = multiplayer_peer_Enet.host
			multiplayer_peer_Enet_peers = multiplayer_peer_Enet.host.get_peers()
			if not multiplayer.is_server():
				is_networking = true
				is_host = false
				get_parent().get_node("Game/Main Menu").hide()
				get_parent().get_node("Game/Game_Controls").show()
				print("Loading level...")
				UnloadScene.unload_scene(get_parent().get_node("Game/Chose_Character"))
		else:
			push_error("Error creating client: ", str(error))	


func hostbyport(port_value):
	if OS.get_name() == "Web":
		var error = multiplayer_peer_websocker.create_server(port_value)
		if error == OK:
			multiplayer.multiplayer_peer = multiplayer_peer_websocker
			multiplayer_peer_websocker.handshake_timeout = 60.0
			if multiplayer.is_server():
				is_networking = true
				is_host = true
				print("Adding UPNP...")
				UPNP_setup()
				print("Adding Broadcast...")
				get_parent().get_node("Game/Main Menu").control.setupbroadcast(username)
				get_parent().get_node("Game/Main Menu").hide()
				print("Loading level...")
				LoadScene.load_scene(get_parent().get_node("Game/Chose_Character"), Globals.level)
		else:
			push_error("Error creating server: " + str(error))
	else:
		var error = multiplayer_peer_Enet.create_server(port_value)
		if error == OK:
			multiplayer.multiplayer_peer = multiplayer_peer_Enet
			multiplayer_peer_Enet_host = multiplayer_peer_Enet.host
			multiplayer_peer_Enet_peers = multiplayer_peer_Enet.host.get_peers()
			if multiplayer.is_server():
				is_networking = true
				is_host = true
				print("Adding UPNP...")
				UPNP_setup()
				print("Adding Broadcast...")
				

				get_parent().get_node("Game/Main Menu").control.setupbroadcast(username)
				get_parent().get_node("Game/Main Menu").hide()
				
				print("Loading level...")
				LoadScene.load_scene(get_parent().get_node("Game/Chose_Character"), Globals.level)
		else:
			push_error("Error creating server: " + str(error))

func _ready():
	if OS.has_feature("dedicated_server") or "s" in OS.get_cmdline_user_args() or "server" in OS.get_cmdline_user_args():
		var args = OS.get_cmdline_user_args()
		for arg in args:
			var key_value = arg.rsplit("=")
			match key_value[0]:
				"port":
					port = key_value[1].to_int()
					lisenerport = key_value[1].to_int() + 1
					broadcasterport = key_value[1].to_int() + 2

		print("port:", port)
		print("ip:", IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1))
		
		await get_tree().create_timer(2).timeout

		hostbyport(port)


func UPNP_setup():
	var upnp = UPNP.new()

	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:  
		print("UPNP discover Failed")
		return
	
	if upnp.get_gateway() and !upnp.get_gateway().is_valid_gateway():
		print("UPNP invalid gateway")
		return 

	var map_result_udp = upnp.add_port_mapping(port, port, "", "UDP")
	if map_result_udp != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP port UDP mapping failed")
		return

	var map_result_tcp = upnp.add_port_mapping(port, port, "", "TCP")
	if map_result_tcp != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP port TCP mapping failed")
		return

var player_name: Array = [
	"Fire",
	"Water",
	"Air",
	"Earth",
]
var player_color: Array = [
	"white",
	"blue",
	"gray",
	"green",
]

var ball_color: Array = [
	"orange",
	"blue",
	"gray",
	"green",
]


var alpha = 1.0 # build

var player_color_dict: Dictionary = {
	0: Color(player_color[0], alpha), # color, alpha
	1: Color(player_color[1], alpha), # color, alpha
	2: Color(player_color[2], alpha), # color, alpha
	3: Color(player_color[3], alpha), # color, alpha
}

var ball_color_dict: Dictionary = {
	0: Color(ball_color[0], alpha), # color, alpha
	1: Color(ball_color[1], alpha), # color, alpha
	2: Color(ball_color[2], alpha), # color, alpha
	3: Color(ball_color[3], alpha), # color, alpha
}

#player


var last_position = null
var max_deaths = 5
var max_hearths = 5

var energys: Dictionary = {
	0: 0, 
	1: 0, 
	2: 0, 
	3: 0, 
}
var score: Dictionary = {
	0: 0, 
	1: 0, 
	2: 0, 
	3: 0, 
}
var hearths: Dictionary = {
	0: max_hearths, 
	1: max_hearths, 
	2: max_hearths, 
	3: max_hearths, 
}
var deaths: Dictionary = {
	0: 0, 
	1: 0, 
	2: 0, 
	3: 0, 
}

@rpc("any_peer", "call_local")
func _sync_time(timer_value):
	Globals.time = timer_value

@rpc("any_peer", "call_local")
func _sync_day(day_value):
	Globals.day = day_value

@rpc("any_peer", "call_local")
func _sync_hour(hour_value):
	Globals.hour = hour_value

@rpc("any_peer", "call_local")
func _sync_minute(minute_value):
	Globals.minute = minute_value

@rpc("any_peer", "call_local")
func _sync_level(level_value):
	Globals.level = level_value

@rpc("any_peer", "call_local")
func _sync_level_int(level_int_value):
	Globals.level_int = level_int_value

func _process(_delta):
	if is_networking:
		if multiplayer.is_server():
			_sync_time.rpc(Globals.time)
			_sync_day.rpc(Globals.day)
			_sync_hour.rpc(Globals.hour)
			_sync_minute.rpc(Globals.minute)
			_sync_level.rpc(Globals.level)
			_sync_level_int.rpc(Globals.level_int)
