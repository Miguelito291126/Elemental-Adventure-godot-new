extends Node

@export var Username: String
@export var Players_Nodes: Dictionary = {}

var player_scene = preload("res://Scenes/player.tscn")

@export var character = "fire"
@export var available_characters: Array = ["fire", "water", "air", "earth"]
@export var assigned_characters: Dictionary = {}

var broadcaster: PacketPeerUDP
var listener: PacketPeerUDP

@export var port = 4444
@export var broadcaster_ip = "255.255.255.255"
@export var ip: String

@export var listener_port =  port - 1
@export var broadcaster_port =  port + 1

var serverbrowser: Control
var multiplayerpeer

var queue_free_nodes: Array = []
var Multiplayerspawner: Array

@export var roominfo = {
	"name": "",
	"playerscount": 0,
}

@onready var broadcasttime = $ServerBrowserTime
func _ready() -> void:
	multiplayer.server_disconnected.connect(MultiplayerServerDisconnected)
	multiplayer.connected_to_server.connect(MultiplayerConnectionServerSucess)
	multiplayer.connection_failed.connect(MultiplayerConnectionFailed)
	multiplayer.peer_connected.connect(MultiplayerPlayerSpawner)
	multiplayer.peer_disconnected.connect(MultiplayerPlayerRemover)

	multiplayerpeer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = multiplayerpeer


func _exit_tree() -> void:
	multiplayer.server_disconnected.disconnect(MultiplayerServerDisconnected)
	multiplayer.connected_to_server.disconnect(MultiplayerConnectionServerSucess)
	multiplayer.connection_failed.disconnect(MultiplayerConnectionFailed)
	multiplayer.peer_connected.disconnect(MultiplayerPlayerSpawner)
	multiplayer.peer_disconnected.disconnect(MultiplayerPlayerRemover)

	CloseUp()

@rpc("any_peer", "call_local")
func assign_element(element: String):
	for c in available_characters:
		if c == element:
			character = element
			break

	if GameController.playernode and is_instance_valid(GameController.playernode):
		GameController.playernode.character = character

	print_role("Se te asignó el personaje:" + element)

@rpc("any_peer", "call_local")
func assign_element_to_player(id, element: String):
	assigned_characters[id] = element
	assign_element.rpc_id(id, element)
	sync_assigned_characters.rpc(assigned_characters)
	print_role("Jugador con ID: " + str(id) + " asignado al personaje: " + element)

@rpc("any_peer", "call_local")
func sync_assigned_characters(data: Dictionary):
	assigned_characters = data.duplicate(true)
	print_role("Diccionario de personajes sincronizado.")


func print_role(msg: String):
	var peer = multiplayer.multiplayer_peer
	
	if peer == null \
	or peer is OfflineMultiplayerPeer \
	or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		print(msg)
		return


	var is_server = multiplayer.is_server() 
	
	if is_server:
		# Azul
		print_rich("[color=blue][Servidor] " + msg + "[/color]")
	else:
		# Amarillo
		print_rich("[color=yellow][Cliente] " + msg + "[/color]")


func close_conection():
	var peer = multiplayer.multiplayer_peer

	# Si no hay peer o está desconectado o es offline → volver al menú
	if peer == null \
	or peer is OfflineMultiplayerPeer \
	or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		get_tree().paused = false
		LoadScene.LoadMainMenu(GameController.levelnode)
		return

	# Si está conectado → cerrar conexión
	peer.close()
	multiplayerpeer.close()

	print(peer.get_class())


func Play_MultiplayerServer():
	multiplayerpeer = ENetMultiplayerPeer.new()
	var error = multiplayerpeer.create_server(port, 4)
	if error == OK:
		multiplayer.multiplayer_peer = multiplayerpeer
		if multiplayer.is_server():
			if OS.has_feature("dedicated_server") or "s" in OS.get_cmdline_user_args() or "server" in OS.get_cmdline_user_args():
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
		multiplayer.multiplayer_peer = multiplayerpeer
		if not multiplayer.is_server():
			print_role("Cliente iniciado.")

			if GameController.chose_characters and is_instance_valid(GameController.chose_characters):
				UnloadScene.unload_scene(GameController.main_menu)
			else:
				LoadScene.LoadCharacterMenu(GameController.main_menu)
	else:
		print_role("Error al iniciar el cliente.")

func MultiplayerPlayerSpawner(id: int = 1):
	if GameController.levelnode and is_instance_valid(GameController.levelnode): 
		var player = player_scene.instantiate()
		player.name = str(id)
		GameController.levelnode.add_child(player, true)
		sync_queue_free_nodes.rpc_id(id, queue_free_nodes)
		sync_assigned_characters.rpc(assigned_characters)
		Sync_Players_Nodes.rpc()

		print_role("Jugador spawneado con el ID:" + str(id))
	else:
		sync_queue_free_nodes.rpc_id(id, queue_free_nodes) 
		sync_assigned_characters.rpc(assigned_characters)
		Sync_Players_Nodes.rpc()
		
		print_role("Jugador no spawneado con el ID:" + str(id))


func MultiplayerPlayerRemover(id: int = 1): 
	var player = Players_Nodes[id]
	if is_instance_valid(player):
		player.queue_free()

		await player.tree_exited
		
		Sync_Players_Nodes.rpc()
		sync_assigned_characters.rpc(assigned_characters)
		print_role("Jugador removido con el ID:" + str(id))
	else:
		Sync_Players_Nodes.rpc()
		sync_assigned_characters.rpc(assigned_characters)
		print_role("El jugador con ID: " + str(id) + " no se encuentra en el juego.")
		



@rpc("any_peer", "call_local")
func Sync_Players_Nodes():
	Players_Nodes.clear()

	for player in get_tree().get_nodes_in_group("player"):
		Players_Nodes[player.id] = player

	
func MultiplayerConnectionFailed():
	print_role("Failed to connect to server")

	Players_Nodes.clear()
	assigned_characters.clear()

	CloseUp()

	multiplayerpeer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = multiplayerpeer

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
	
	Players_Nodes.clear()
	assigned_characters.clear()

	CloseUp()

	multiplayerpeer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = multiplayerpeer

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

func SetUpLisener():
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

@rpc("any_peer", "call_local")
func sync_queue_free_nodes(nodes: Array):
	for node_path in nodes:
		var node = get_tree().get_current_scene().get_node_or_null(node_path)
		if node:
			# Enemigos
			if node.is_in_group("enemy") and not node.death:
				remove_node_synced.rpc(node_path)
			# Monedas
			elif node.is_in_group("coins") and not node.collected:
				remove_node_synced.rpc(node_path)
			# Corazones
			elif node.is_in_group("hearth") and not node.collected:
				remove_node_synced.rpc(node_path)

			print_role("Nodo eliminado: " + node_path)
		else:
			# Log más claro para debugging
			print_role("Nodo no encontrado: " + str(node_path))

@rpc("any_peer", "call_local")
func remove_node_synced(node_path: String):
	var node = get_tree().get_current_scene().get_node_or_null(node_path)
	if node and is_instance_valid(node):
		node.queue_free()
		print_role("Nodo eliminado sincronizado: " + node_path)


func add_queue_free_nodes(Name: String):

	if not multiplayer.is_server():
		return

	if not queue_free_nodes.has(Name):
		queue_free_nodes.append(Name)


func remove_queue_free_nodes(Name: String):

	if not multiplayer.is_server():
		return

	if queue_free_nodes.has(Name):
		queue_free_nodes.erase(Name)

func remove_all_queue_free_nodes():

	if not multiplayer.is_server():
		return

	for i in queue_free_nodes:
		remove_queue_free_nodes(i)
