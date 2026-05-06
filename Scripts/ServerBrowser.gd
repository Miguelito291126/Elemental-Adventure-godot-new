extends Control

@onready var list = $List
const TIMEOUT = 3.0

var Serverinfo: PackedScene = preload("res://Scenes/server_info.tscn")

func _ready():
	Network.serverbrowser = self

	var cleanTimer = Timer.new()
	cleanTimer.wait_time = 3
	cleanTimer.autostart = true
	cleanTimer.timeout.connect(RefreshServerList)
	add_child(cleanTimer)
	
	RefreshServerList() # Primera carga

# En ServerBrowser.gd
func RefreshServerList():
	if not Network.use_steam:
		return
	
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

		currentinfo.lobby_id = Steam.getLobbyData(lobby_id, "lobby_id") # El ID del lobby guardado[cite: 2]
		currentinfo.host_id = Steam.getLobbyData(lobby_id, "host_id") # El ID del host guardado[cite: 2]
		currentinfo.last_seen = Time.get_unix_time_from_system() # Guardamos el tiempo actual para
		
		# Conectamos el botón de unirse[cite: 1]
		var btn = currentinfo.get_node_or_null("Join")
		if btn:
			btn.pressed.connect(currentinfo.join_server)

		list.add_child(currentinfo)
