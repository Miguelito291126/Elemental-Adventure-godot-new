extends Control

@onready var list = $List
const TIMEOUT = 3.0

var Serverinfo: PackedScene = preload("res://Scenes/server_info.tscn")

func _ready():
	Network.serverbrowser = self

	var cleanTimer = Timer.new()
	# Aumentamos a 3 o 5 segundos para no saturar y permitir clics estables
	cleanTimer.wait_time = 1.0 
	cleanTimer.autostart = true
	cleanTimer.timeout.connect(RefreshServerList)
	add_child(cleanTimer)
	
	RefreshServerList() # Primera carga

# En ServerBrowser.gd
func RefreshServerList():
	for n in list.get_children():
		n.queue_free()
		
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListStringFilter("game_id", "elemental_adventure", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func _on_steam_lobbies_received(lobbies: Array):
	for n in list.get_children():
		n.queue_free()

	for lobby_id in lobbies:
		# Extraemos la información que guardamos al crear el lobby[cite: 2]
		var s_name = Steam.getLobbyData(lobby_id, "name")
		var s_players = Steam.getLobbyData(lobby_id, "players_count")

		var currentinfo = Serverinfo.instantiate()

		if currentinfo.has_node("Name"):
			currentinfo.get_node("Name").text = str(s_name) + " - "

		if currentinfo.has_node("Players"):
			currentinfo.get_node("Players").text = str(s_players) + " / 4 - "

		# Guardamos los datos técnicos para el botón "Join"
		currentinfo.host_id = Steam.getLobbyData(lobby_id, "host_rpc_id")# La ID de Steam del host[cite: 2]
		currentinfo.ip_local_Change = Steam.getLobbyData(lobby_id, "local_ip") # La IP local guardada[cite: 2]
		currentinfo.port_Change = Steam.getLobbyData(lobby_id, "port") # El puerto guardado[cite: 2]

		# Conectamos el botón de unirse[cite: 1]
		var btn = currentinfo.get_node_or_null("Join")
		if btn:
			btn.pressed.connect(currentinfo.join_server)

		list.add_child(currentinfo)