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
var is_loading_character_menu: bool = false
var server_is_in_level: bool = false

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
func request_character(element: String):
	var sender = multiplayer.get_remote_sender_id()

	# Si sender_id == 0, significa que fue una llamada directa (no RPC)
	# Si es el servidor, usamos su ID único
	if sender == 0:
		if multiplayer.is_server():
			# El servidor está llamando directamente (no por RPC)
			sender = multiplayer.get_unique_id()
		else:
			# El cliente está ejecutando localmente (por call_local)
			# No hacemos nada aquí, el servidor ya procesará la solicitud
			return

	# Solo el servidor puede ejecutar assign_element_to_player
	if not multiplayer.is_server():
		return

	assign_element_to_player(sender, element)



@rpc("authority", "call_local")
func assign_element_to_player(id: int, element: String):
	if not is_character_available(element):
		character_denied.rpc_id(id, element)
		return

	# El servidor es quien ejecuta esta función (authority), actualizamos el diccionario:
	assigned_characters[id] = element

	# Notificamos al jugador concreto (asigna el personaje localmente en el cliente)
	assign_element.rpc_id(id, element)

	# Sincronizamos a todos los peers: enviamos la copia por RPC...
	sync_assigned_characters.rpc(assigned_characters)

	# ...y también aplicamos la sincronización localmente AHORA para el servidor
	# (evita que el servidor espere a que el RPC vuelva a él)
	sync_assigned_characters(assigned_characters)




@rpc("authority", "call_local")
func hide_character_selection_menu():
	# Ocultar/eliminar la pantalla de elegir personaje en todos los clientes
	if GameController.chose_characters and is_instance_valid(GameController.chose_characters):
		UnloadScene.unload_scene(GameController.chose_characters)



@rpc("any_peer", "call_local")
func request_server_level_state():
	# El cliente solicita al servidor el estado del nivel
	if not multiplayer.is_server():
		return
	
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0:
		return
	
	var is_in_level = GameController.levelnode != null and is_instance_valid(GameController.levelnode)
	server_level_state.rpc_id(sender, is_in_level)

@rpc("authority")
func server_level_state(is_in_level: bool):
	# El cliente recibe el estado del servidor
	if not multiplayer.is_server():
		server_is_in_level = is_in_level
		if is_in_level:
			# El servidor ya está en el nivel, no cargar la pantalla de elegir personaje
			hide_character_selection_menu()
			
@rpc("any_peer", "call_local")
func request_sync_assigned_characters():
	# Solo el servidor puede responder a esta solicitud
	if not multiplayer.is_server():
		return
	
	var sender = multiplayer.get_remote_sender_id()
	# Si sender == 0, significa que fue una llamada directa (no RPC)
	if sender == 0:
		if multiplayer.is_server():
			# El servidor está llamando directamente, no hacer nada
			return
		else:
			# El cliente está ejecutando localmente (por call_local)
			# No hacemos nada aquí, el servidor ya procesará la solicitud
			return
	
	# Enviar la sincronización al cliente que la solicitó
	sync_assigned_characters.rpc_id(sender, assigned_characters)


@rpc("authority", "call_local")
func sync_assigned_characters(data: Dictionary):
	assigned_characters = data.duplicate(true)
	
	if GameController.chose_characters and is_instance_valid(GameController.chose_characters):
		GameController.chose_characters.update_character_buttons()
		


func get_next_available_character() -> String:
	# Obtener el siguiente personaje disponible en orden: fire, water, air, earth
	for char_name in available_characters:
		if is_character_available(char_name):
			return char_name
	# Si no hay personajes disponibles, devolver el primero (no debería pasar)
	return available_characters[0] if available_characters.size() > 0 else "fire"


func is_character_available(element: String) -> bool:
	for id in assigned_characters:
		if assigned_characters[id] == element:
			return false  # Ya está usado


	return true

@rpc("any_peer", "call_local")
func character_denied(element: String):
	print_role("El personaje " + element + " está ocupado. Elige otro.")



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
		print_role("Conectando al servidor...")
		multiplayer.multiplayer_peer = multiplayerpeer
		if not multiplayer.is_server():
			print_role("Cliente iniciado.")
			# No cargar la escena aquí, esperar a que la conexión se confirme
	else:
		print_role("Error al iniciar el cliente.")

func MultiplayerPlayerSpawner(id: int = 1):
	# Solo el servidor puede spawnear jugadores y sincronizar
	if not multiplayer.is_server():
		return
		
	if GameController.levelnode and is_instance_valid(GameController.levelnode): 
		var player = player_scene.instantiate()
		player.name = str(id)
		GameController.levelnode.add_child(player, true)
		
		# Si el jugador no tiene personaje asignado y el servidor ya está en el nivel,
		# asignar automáticamente el siguiente personaje disponible
		if not id in assigned_characters:
			var next_character = get_next_available_character()
			assigned_characters[id] = next_character
			assign_element.rpc_id(id, next_character)
			print_role("Personaje automático asignado al jugador " + str(id) + ": " + next_character)
		
		sync_assigned_characters.rpc(assigned_characters)
		sync_assigned_characters(assigned_characters)  # Actualizar localmente en el servidor
		sync_queue_free_nodes.rpc_id(id, queue_free_nodes)
		Sync_Players_Nodes.rpc()
		
		# Si el servidor ya está en el nivel, notificar al cliente para que oculte la pantalla
		hide_character_selection_menu.rpc_id(id)

		print_role("Jugador spawneado con el ID:" + str(id))
	else:

		sync_assigned_characters.rpc(assigned_characters)
		sync_assigned_characters(assigned_characters)  # Actualizar localmente en el servidor
		sync_queue_free_nodes.rpc_id(id, queue_free_nodes) 
		Sync_Players_Nodes.rpc()
		
		print_role("Jugador no spawneado con el ID:" + str(id))


func MultiplayerPlayerRemover(id: int = 1):
	# Solo el servidor puede remover jugadores y sincronizar
	if not multiplayer.is_server():
		return
		
	# Verificar si el jugador existe en el diccionario antes de acceder
	if id in Players_Nodes:
		var player = Players_Nodes[id]
		if is_instance_valid(player):
			player.queue_free()

			await player.tree_exited
			
			# Remover el personaje asignado del jugador desconectado
			if id in assigned_characters:
				assigned_characters.erase(id)
			
			Sync_Players_Nodes.rpc()
			sync_assigned_characters.rpc(assigned_characters)
			sync_assigned_characters(assigned_characters)  # Actualizar localmente en el servidor
			print_role("Jugador removido con el ID:" + str(id))
		else:
			# El jugador no es válido, pero aún así remover de assigned_characters
			if id in assigned_characters:
				assigned_characters.erase(id)
			
			Sync_Players_Nodes.rpc()
			sync_assigned_characters.rpc(assigned_characters)
			sync_assigned_characters(assigned_characters)  # Actualizar localmente en el servidor
			print_role("Jugador con ID: " + str(id) + " no es válido, pero se removió de la lista.")
	else:
		# El jugador no está en Players_Nodes, pero aún así remover de assigned_characters si existe
		if id in assigned_characters:
			assigned_characters.erase(id)
		
		Sync_Players_Nodes.rpc()
		sync_assigned_characters.rpc(assigned_characters)
		sync_assigned_characters(assigned_characters)  # Actualizar localmente en el servidor
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
	
	# Solo cargar la escena de elegir personaje si somos cliente y no existe ya
	if not multiplayer.is_server():
		# Solicitar al servidor el estado del nivel antes de cargar cualquier escena
		request_server_level_state.rpc()
		
		# Esperar un momento para recibir la respuesta del servidor
		await get_tree().create_timer(0.2).timeout
		
		# Verificar si el servidor ya está en el nivel (después de recibir la respuesta)
		if server_is_in_level:
			# El servidor ya está en el nivel, no mostrar la pantalla de elegir personaje
			# Ocultar la pantalla si existe
			if GameController.main_menu and is_instance_valid(GameController.main_menu):
				UnloadScene.unload_scene(GameController.main_menu)
				
			hide_character_selection_menu()
			return
		
		# Evitar cargar la escena dos veces
		if is_loading_character_menu:
			return
		
		if GameController.chose_characters and is_instance_valid(GameController.chose_characters):
			# La escena ya está cargada, solo actualizar y solicitar sincronización
			if GameController.main_menu and is_instance_valid(GameController.main_menu):
				UnloadScene.unload_scene(GameController.main_menu)
			# Solicitar sincronización después de un pequeño delay para asegurar que la escena esté lista
			await get_tree().create_timer(0.1).timeout
			if GameController.chose_characters and is_instance_valid(GameController.chose_characters):
				GameController.chose_characters.request_sync_assigned_characters()
		else:
			# Marcar que estamos cargando para evitar cargas duplicadas
			is_loading_character_menu = true
			# Cargar la escena de elegir personaje solo si el servidor no está en el nivel
			LoadScene.LoadCharacterMenu(GameController.main_menu)
			# La escena solicitará la sincronización automáticamente en su _ready()
			# Resetear el flag después de un momento
			await get_tree().create_timer(0.5).timeout
			is_loading_character_menu = false
	
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
			# Si el nodo está en la lista, eliminarlo directamente sin verificar estado
			# Esto asegura que los clientes que se conectan después eliminen los nodos correctos
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
