extends Node

@export var Username = "Player"
@export var Players_Nodes: Dictionary = {}

var player_scene = preload("res://Scenes/player.tscn")

@export var character = "fire"
@export var available_elements = ["fire", "water", "air", "earth"]
@export var assigned_characters: Dictionary = {}

var broadcaster: PacketPeerUDP
var listener: PacketPeerUDP

@export var port = 4444
@export var broadcaster_ip = "255.255.255.255"
@export var ip = "localhost"

@export var listener_port =  port - 1
@export var broadcaster_port =  port + 1

var serverbrowser: Control
var multiplayerpeer : ENetMultiplayerPeer

var queue_free_nodes: Array = []

var IsNetwork = false

var Multiplayerspawner: Array

@export var roominfo = {
	"name": "",
	"playerscount": 0,
}

@onready var broadcasttime = $ServerBrowserTime
func _ready() -> void:
	get_tree().get_multiplayer().server_disconnected.connect(MultiplayerServerDisconnected)
	get_tree().get_multiplayer().connected_to_server.connect(MultiplayerConnectionServerSucess)
	get_tree().get_multiplayer().connection_failed.connect(MultiplayerConnectionFailed)
	get_tree().get_multiplayer().peer_connected.connect(MultiplayerPlayerSpawner)
	get_tree().get_multiplayer().peer_disconnected.connect(MultiplayerPlayerRemover)

	if OS.has_feature("dedicated_server"):

		var args = OS.get_cmdline_user_args()
		for arg in args:
			var key_value = arg.rsplit("=")
			match key_value[0]:
				"port":
					port = key_value[1].to_int()
					listener_port = key_value[1].to_int() + 1
					broadcaster_port = key_value[1].to_int() + 2

		print_role("port:" + str(port))
		print_role("ip:" + IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4))
		
		print_role("Iniciando servidor dedicado...")
		
		await get_tree().create_timer(2).timeout

		Play_MultiplayerServer()



func _exit_tree() -> void:
	get_tree().get_multiplayer().server_disconnected.disconnect(MultiplayerServerDisconnected)
	get_tree().get_multiplayer().connected_to_server.disconnect(MultiplayerConnectionServerSucess)
	get_tree().get_multiplayer().connection_failed.disconnect(MultiplayerConnectionFailed)
	get_tree().get_multiplayer().peer_connected.disconnect(MultiplayerPlayerSpawner)
	get_tree().get_multiplayer().peer_disconnected.disconnect(MultiplayerPlayerRemover)

	CloseUp()

@rpc("any_peer", "call_local")
func assign_element(element: String):
	character = element
	print_role("Se te asignó el personaje:" + element)

@rpc("authority", "call_local")
func assign_element_to_player(id: int) -> void:
	# Si ya tiene un personaje asignado, reutilizarlo
	if assigned_characters.has(id):
		assign_element.rpc_id(id, assigned_characters[id])
		return

	# Determinar el primer personaje libre (manteniendo el orden: fire, water, air, earth)
	var used := []
	for v in assigned_characters.values():
		used.append(v)

	var select_character: String = ""
	for e in available_elements:
		if e in used:
			continue
		select_character = e
		break

	# Si por alguna razón ya están todos usados (más de 4 jugadores),
	# asignamos el siguiente de forma cíclica (o aleatoria si prefieres)
	if select_character == "":
		select_character = available_elements[randi() % available_elements.size()]

	assigned_characters[id] = select_character
	assign_element.rpc_id(id, select_character)

	# Mensaje para debug (mostrar el "número de jugador" según el orden actual)
	var player_number := used.size() + 1
	print_role("Jugador %d asignado con éxito el personaje: %s" % [player_number, select_character])


func remove_element_from_player(id: int) -> void:
	if assigned_characters.has(id):
		assigned_characters.erase(id)
		print_role("Jugador con ID: %d ha sido eliminado de la lista de personajes asignados." % id)
	else:
		print_role("Jugador con ID: %d no tenía un personaje asignado." % id)

func print_role(msg: String):
	if IsNetwork:
		var is_server = get_tree().get_multiplayer().is_server() 
		
		if is_server:
			# Azul
			print_rich("[color=blue][Servidor] " + msg + "[/color]")
		else:
			# Amarillo
			print_rich("[color=yellow][Cliente] " + msg + "[/color]")
	else:
		print( msg )



func Play_MultiplayerServer():
	multiplayerpeer = ENetMultiplayerPeer.new()
	var error = multiplayerpeer.create_server(port, 4)
	if error == OK:
		get_tree().get_multiplayer().multiplayer_peer = multiplayerpeer
		if get_tree().get_multiplayer().is_server():
			IsNetwork = true

			if OS.has_feature("dedicated_server"):
				print_role("Servidor dedicado iniciado.")

				await get_tree().create_timer(2).timeout
				
				SetUpBroadcast(Username)
				LoadScene.load_level_scene(GameController.main_menu)
			else:
				SetUpBroadcast(Username)
				LoadScene.LoadCharacterMenu(GameController.main_menu)
	else:
		print_role("Error al iniciar el servidor.")

func Play_MultiplayerClient():
	multiplayerpeer = ENetMultiplayerPeer.new()
	var error =  multiplayerpeer.create_client(ip, port)
	if error == OK:
		print_role("Conectado al servidor...")
		get_tree().get_multiplayer().multiplayer_peer = multiplayerpeer
		if not get_tree().get_multiplayer().is_server():
			IsNetwork = true
			print_role("Cliente iniciado.")
			UnloadScene.unload_scene(GameController.main_menu)

	else:
		print_role("Error al iniciar el cliente.")

func MultiplayerPlayerSpawner(id: int = 1):

	if IsNetwork:
		if not get_tree().get_multiplayer().is_server():
			return
	
	if GameController.levelnode and is_instance_valid(GameController.levelnode):
		var player = player_scene.instantiate()
		player.name = str(id)
		player.id = player.name
		GameController.levelnode.add_child(player, true)
		assign_element_to_player(id)
		Sync_Players_Nodes.rpc()
		sync_queue_free_nodes.rpc_id(id, queue_free_nodes)
		print_role("Jugador spawneado con el ID:" + str(id))
	else:
		Sync_Players_Nodes.rpc()
		sync_queue_free_nodes.rpc_id(id, queue_free_nodes)
		print_role("Jugador no spawneado con el ID:" + str(id))


func MultiplayerPlayerRemover(id: int = 1):
	if IsNetwork:
		if not get_tree().get_multiplayer().is_server():
			return
	

	var player = Players_Nodes[id]
	if is_instance_valid(player):
		player.queue_free()

		await player.tree_exited

		remove_element_from_player(id)
		
		Sync_Players_Nodes.rpc()
		print_role("Jugador removido con el ID:" + str(id))
	else:
		Sync_Players_Nodes.rpc()
		print_role("El jugador con ID: " + str(id) + " no se encuentra en el juego.")
		



@rpc("any_peer", "call_local")
func Sync_Players_Nodes():
	Players_Nodes.clear()

	for player in get_tree().get_nodes_in_group("player"):
		Players_Nodes[player.name.to_int()] = player

	
func MultiplayerConnectionFailed():
	print_role("Failed to connect to server")

	if multiplayerpeer:
		multiplayerpeer = null

	if IsNetwork:
		IsNetwork = false

	Players_Nodes.clear()

	CloseUp()

	if GameController.levelnode and is_instance_valid(GameController.levelnode):
		LoadScene.LoadMainMenu(GameController.levelnode)
	elif GameController.game_over_menu and is_instance_valid(GameController.game_over_menu):
		LoadScene.LoadMainMenu(GameController.game_over_menu)
	elif GameController.victory_menu and is_instance_valid(GameController.victory_menu):
		LoadScene.LoadMainMenu(GameController.victory_menu)
	else:
		print_role("No valid scene to load main menu.")
		UnloadScene.unload_scene(GameController.levelnode) # ← Added to prevent errors
	

func MultiplayerConnectionServerSucess():
	print_role("Connected to server")
	
func MultiplayerServerDisconnected():
	print_role("Disconnecting from server...")
	
	if multiplayerpeer:
		multiplayerpeer = null

	if IsNetwork:
		IsNetwork = false

	Players_Nodes.clear()

	CloseUp()

	if is_instance_valid(GameController.levelnode):
		LoadScene.LoadMainMenu(GameController.levelnode)
	elif is_instance_valid(GameController.game_over_menu):
		LoadScene.LoadMainMenu(GameController.game_over_menu)
	elif is_instance_valid(GameController.victory_menu):
		LoadScene.LoadMainMenu(GameController.victory_menu)
	else:
		print_role("No valid scene to load main menu.")
		UnloadScene.unload_scene(GameController.levelnode) # ← Added to prevent errors

func SetUpBroadcast(Name: String,) -> void:
	roominfo.name = Name
	roominfo.playerscount = Players_Nodes.size()

	broadcaster = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	broadcaster.set_dest_address(broadcaster_ip, listener_port)

	var ok = broadcaster.bind(broadcaster_port)
	if ok == OK:
		print_role("all correct to port broadcaster: " + str(broadcaster_port) + " :D")
		if is_instance_valid(serverbrowser) and serverbrowser != null:
			serverbrowser.label.text = "Broadcasting on port: " + str(broadcaster_port)
	else:
		print_role("failed to port broadcaster: " + str(broadcaster_port) + " D:")
		if is_instance_valid(serverbrowser) and serverbrowser != null:
			serverbrowser.label.text = "Failed to start broadcaster"

	if broadcasttime != null:
		broadcasttime.start()

func CloseUp():
	
	if listener != null:
		listener.close()

	if broadcasttime != null:
		broadcasttime.stop()

	if broadcaster != null:
		broadcaster.close()

	print_role("Closed broadcaster and listener")

func SetUp():
	listener = PacketPeerUDP.new()
	var ok = listener.bind(listener_port)
	if ok == OK:
		print_role("all correct to port listener: " + str(listener_port) + " :D")
		await get_tree().create_timer(1).timeout
		if serverbrowser:
			serverbrowser.label.text = "Listener on port: " + str(listener_port)
	else:
		print_role("failed to port listener: " + str(listener_port) + " D:")
		await get_tree().create_timer(1).timeout
		if serverbrowser:
			serverbrowser.label.text = "Failed to start listener"

func _on_server_browser_time_timeout() -> void:
	roominfo.playerscount = Players_Nodes.size()
	var data = JSON.stringify(roominfo)
	var packet = data.to_ascii_buffer()
	if broadcaster != null:
		broadcaster.put_packet(packet)

@rpc("authority", "call_local")
func sync_queue_free_nodes(nodes: Array):
	for node_path in nodes:
		var node = get_tree().get_current_scene().get_node_or_null(node_path)
		if node:
			# Enemigos
			if node.is_in_group("enemy") and not node.death:
				node.queue_free()
			# Monedas
			elif node.is_in_group("coins") and not node.collected:
				node.queue_free()
			# Corazones
			elif node.is_in_group("hearth") and not node.collected:
				node.queue_free()
			else:
				print_role("Nodo ya procesado o no válido: " + str(node_path))

func add_queue_free_nodes(Name: String):
	if IsNetwork:
		if not get_tree().get_multiplayer().is_server():
			return

	if not queue_free_nodes.has(Name):
		queue_free_nodes.append(Name)


func remove_queue_free_nodes(Name: String):
	if IsNetwork:
		if not get_tree().get_multiplayer().is_server():
			return

	if queue_free_nodes.has(Name):
		queue_free_nodes.erase(Name)

func remove_all_queue_free_nodes():
	if IsNetwork:
		if not get_tree().get_multiplayer().is_server():
			return

	for i in queue_free_nodes:
		remove_queue_free_nodes(i)
