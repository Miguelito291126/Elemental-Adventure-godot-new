extends Node

signal queue_synced

@export var Username: String = "Player"
@export var Players_Nodes: Dictionary = {}

var player_scene = preload("res://Scenes/player.tscn")

@export var character = "fire"
@export var available_characters: Array = ["fire", "water", "air", "earth"]
@export var assigned_characters: Dictionary = {}

@export var port: int = 4444
@export var ip: String
@export var use_steam: bool = false
@export var steam_id: int
@export var steam_lobby_id: int = 0
@export var PublicIp: String
@export var LocalIp: String

var serverbrowser: Control
var multiplayerpeer

var queue_free_nodes: Array = []
var is_loading_character_menu: bool = false
var server_is_in_level: bool = false

@export var roominfo = {
	"name": "",
	"playerscount": 0,
}

@onready var http: HTTPRequest = $HTTPRequest
@export var masterServerUrl = "http://miguelito2911.serveminecraft.net:5000"
@export var private_mode = false


func _ready() -> void:
	multiplayer.server_disconnected.connect(MultiplayerServerDisconnected)
	multiplayer.connected_to_server.connect(MultiplayerConnectionServerSucess)
	multiplayer.connection_failed.connect(MultiplayerConnectionFailed)
	multiplayer.peer_connected.connect(MultiplayerPlayerSpawner)
	multiplayer.peer_disconnected.connect(MultiplayerPlayerRemover)

	multiplayerpeer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = multiplayerpeer
	
	# Inicializar Steam
	InitSteam()
	FetchLocalIp()
	FetchPublicIp()

func InitSteam():
	var is_steam_running = Steam.steamInit()
	if is_steam_running:		
		use_steam = true
		print_role("Steam inicializado correctamente.")
		
		# Configurar señales de Lobbies
		Steam.lobby_created.connect(_on_lobby_created)	
		Steam.lobby_match_list.connect(_on_lobby_match_list)
		Steam.lobby_joined.connect(_on_lobby_joined)

		steam_id = Steam.getSteamID()
		Username = Steam.getPersonaName()
	else:
		use_steam = false
		print_role("Steam no se pudo inicializar")



func _on_lobby_match_list(lobbies: Array):
	# Esta función se activa cuando Steam termina de buscar partidas
	print_role("Se encontraron " + str(lobbies.size()) + " lobbies en Steam.")
	
	# Si tienes una referencia al buscador de servidores, le pasamos los datos
	if serverbrowser and is_instance_valid(serverbrowser):
		serverbrowser._on_steam_lobbies_received(lobbies)
		
func _on_lobby_created(connect_status: int, lobby_id: int):
	if connect_status == 1:
		print_role("Lobby de Steam creado con éxito. ID: " + str(lobby_id)) 
		steam_lobby_id = lobby_id

		Steam.setLobbyData(lobby_id, "game_id", "elemental_adventure")
		Steam.setLobbyData(lobby_id, "name", Username)
		Steam.setLobbyData(lobby_id, "public_ip", PublicIp)
		Steam.setLobbyData(lobby_id, "local_ip", LocalIp)
		Steam.setLobbyData(lobby_id, "players_count", str(Players_Nodes.size()))
		Steam.setLobbyData(lobby_id, "port", str(port))
		Steam.setLobbyData(lobby_id, "lobby_id", str(lobby_id))
		Steam.setLobbyData(lobby_id, "host_id", str(steam_id))
		
		Play_MultiplayerServer(port)
	else:
		print_role("Error al crear el lobby de Steam: " + str(connect_status))

func _on_lobby_joined(lobby_id: int, perms: int, locked: bool, reponse: int):
	if reponse == 1:
		print_role("Lobby de Steam unido con éxito. ID: " + str(lobby_id))
		steam_lobby_id = lobby_id
		var lobby_owner = Steam.getLobbyOwner(lobby_id)

		await get_tree().process_frame
		if lobby_owner != Steam.getSteamID():
			Play_MultiplayerClient(lobby_id)

func _exit_tree() -> void:
	multiplayer.server_disconnected.disconnect(MultiplayerServerDisconnected)
	multiplayer.connected_to_server.disconnect(MultiplayerConnectionServerSucess)
	multiplayer.connection_failed.disconnect(MultiplayerConnectionFailed)
	multiplayer.peer_connected.disconnect(MultiplayerPlayerSpawner)
	multiplayer.peer_disconnected.disconnect(MultiplayerPlayerRemover)	

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



func assign_element_to_player(id: int, element: String):
	var chosen_char = element

	if chosen_char == null or chosen_char == "" or not is_character_available(element):
		chosen_char = get_next_available_character()

	if chosen_char == null or chosen_char == "" or not is_character_available(element):
		print_role("No hay personaje disponible para el id " + str(id))
		return false

	# El servidor es quien ejecuta esta función (authority), actualizamos el diccionario:
	assigned_characters[id] = chosen_char

	# Notificamos al jugador concreto (asigna el personaje localmente en el cliente)
	assign_element.rpc_id(id, chosen_char)

	# Sincronizamos a todos los peers: enviamos la copia por RPC...
	sync_assigned_characters.rpc(assigned_characters)

	return true




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

@rpc("any_peer", "call_local")
func close_conection():
	var peer = multiplayer.multiplayer_peer
	
	# Si no hay peer o está desconectado o es offline → volver al menú
	if peer == null \
	or peer is OfflineMultiplayerPeer \
	or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		MultiplayerServerDisconnected()
		return

	# Si está conectado → cerrar conexión
	peer.close()
	multiplayerpeer.close()

func create_steam_lobby():
	if private_mode:
		Steam.createLobby(Steam.LOBBY_TYPE_PRIVATE, 4) # 4 es el máximo de jugadores[cite: 2]
	else:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4) # 4 es el máximo de jugadores[cite: 2]

func join_steam_lobby(lobby_id: int):
	Steam.joinLobby(lobby_id)



func Play_MultiplayerServer(server_port: int = 4444):
	
	if multiplayer.multiplayer_peer or multiplayerpeer:
		multiplayerpeer.close()
		multiplayer.multiplayer_peer.close()

	if use_steam:
		multiplayerpeer = SteamMultiplayerPeer.new()
		var error = multiplayerpeer.create_host(server_port)
		if error == OK:
			multiplayer.multiplayer_peer = multiplayerpeer
			if multiplayer.is_server():		

				if OS.has_feature("dedicated_server") or "s" in OS.get_cmdline_user_args() or "server" in OS.get_cmdline_user_args():
					print_role("Servidor dedicado iniciado.")

					await get_tree().create_timer(2).timeout
					
					LoadScene.load_level_scene(GameController.main_menu)
				else:
					LoadScene.LoadCharacterMenu(GameController.main_menu)
		else:
			print_role("Error al iniciar el servidor.")
	else:
		if not private_mode:
			UpnpSetup(server_port)

		multiplayerpeer = ENetMultiplayerPeer.new()
		var error = multiplayerpeer.create_server(server_port)
		if error == OK:
			multiplayer.multiplayer_peer = multiplayerpeer
			if multiplayer.is_server():		

				if OS.has_feature("dedicated_server") or "s" in OS.get_cmdline_user_args() or "server" in OS.get_cmdline_user_args():
					print_role("Servidor dedicado iniciado.")

					await get_tree().create_timer(2).timeout
					
					LoadScene.load_level_scene(GameController.main_menu)

				else:
					LoadScene.LoadCharacterMenu(GameController.main_menu)
		else:
			print_role("Error al iniciar el servidor.")


func Play_MultiplayerClientNoSteam(ip: String, port: int ):
	
	if multiplayer.multiplayer_peer or multiplayerpeer:
		multiplayerpeer.close()
		multiplayer.multiplayer_peer.close()

	multiplayerpeer = ENetMultiplayerPeer.new()
	var error =  multiplayerpeer.create_client(ip, port)
	if error == OK:
		multiplayer.multiplayer_peer = multiplayerpeer
		print_role("Conectando al servidor...")
		if not multiplayer.is_server():
			print_role("Cliente iniciado.")
	else:
		print_role("Error al iniciar el cliente.")

func Play_MultiplayerClient(lobby_id: int = 0):

	if multiplayer.multiplayer_peer or multiplayerpeer:
		multiplayerpeer.close()
		multiplayer.multiplayer_peer.close()

	var host_id = Steam.getLobbyOwner(lobby_id)
	if host_id == 0:
		host_id = int(Steam.getLobbyData(lobby_id, "host_id"))

	multiplayerpeer = SteamMultiplayerPeer.new()
	var error =  multiplayerpeer.create_client(host_id, port)
	if error == OK:
		multiplayer.multiplayer_peer = multiplayerpeer
		print_role("Conectando al servidor...")
		if not multiplayer.is_server():
			print_role("Cliente iniciado.")
	else:
		print_role("Error al iniciar el cliente.")


func sync_all():
	sync_assigned_characters.rpc(assigned_characters)
	sync_queue_free_nodes.rpc(queue_free_nodes)
	Sync_Players_Nodes.rpc()
	if multiplayer.is_server() and steam_lobby_id != 0 and use_steam:
		Steam.setLobbyData(steam_lobby_id, "players_count", str(Players_Nodes.size()))

func MultiplayerPlayerSpawner(id: int = 1):
	# Solo el servidor puede spawnear jugadores y sincronizar
	if not multiplayer.is_server():
		return
		
	if GameController.levelnode and is_instance_valid(GameController.levelnode): 
		var player = player_scene.instantiate()
		player.name = str(id)
		GameController.levelnode.add_child(player, true)
		
		var is_ok = true

		if not id in assigned_characters:
			var next_character = get_next_available_character()
			is_ok = assign_element_to_player(id, next_character)
			print_role("Personaje automático asignado al jugador " + str(id) + ": " + next_character)
		
		if is_ok:
			sync_all()
		
			# Si el servidor ya está en el nivel, notificar al cliente para que oculte la pantalla
			hide_character_selection_menu.rpc_id(id)
			print_role("Jugador spawneado con el ID:" + str(id))
		else:
			sync_all()
			print_role("No se pudo añadir al jugador con el id: " + str(id))	


	else:
		sync_all()
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
			
			sync_all()
			print_role("Jugador removido con el ID:" + str(id))
		else:
			# El jugador no es válido, pero aún así remover de assigned_characters
			if id in assigned_characters:
				assigned_characters.erase(id)
			
			sync_all()
			print_role("Jugador con ID: " + str(id) + " no es válido, pero se removió de la lista.")
	else:
		# El jugador no está en Players_Nodes, pero aún así remover de assigned_characters si existe
		if id in assigned_characters:
			assigned_characters.erase(id)
		
		sync_all()
		print_role("El jugador con ID: " + str(id) + " no se encuentra en el juego.")
		



@rpc("any_peer", "call_local")
func Sync_Players_Nodes():
	Players_Nodes.clear()

	for player in get_tree().get_nodes_in_group("player"):
		Players_Nodes[player.id] = player

func clear_all():
	Players_Nodes.clear()
	assigned_characters.clear()
	queue_free_nodes.clear()

func MultiplayerConnectionFailed():
	print_role("Failed to connect to server")
	clear_all()

	if steam_lobby_id != 0 and use_steam:
		Steam.leaveLobby(steam_lobby_id)
		steam_lobby_id = 0
		print_role("Saliendo del lobby de Steam.")

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
	

func generate_unique_id(node: Node) -> String:
	return "id_" + str(node.get_path().hash())

func generate_unique_id_random(node: Node) -> String:
	return "id_" + str(node.get_path().hash())  + "_" + str(randi())


func MultiplayerConnectionServerSucess():
	print_role("Connected to server")
	clear_all()
	
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
	clear_all()

	if steam_lobby_id != 0 and use_steam:
		Steam.leaveLobby(steam_lobby_id)
		steam_lobby_id = 0

		print_role("Saliendo del lobby de Steam.")

	multiplayerpeer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = multiplayerpeer

	if GameController.levelnode and is_instance_valid(GameController.levelnode):
		LoadScene.LoadMainMenu(GameController.levelnode)
	elif GameController.game_over_menu and is_instance_valid(GameController.game_over_menu):
		LoadScene.LoadMainMenu(GameController.game_over_menu)
	elif GameController.victory_menu and is_instance_valid(GameController.victory_menu):
		LoadScene.LoadMainMenu(GameController.victory_menu)
	elif GameController.chose_characters and is_instance_valid(GameController.chose_characters):
		LoadScene.LoadMainMenu(GameController.chose_characters)
	else:
		print_role("No valid scene to load main menu.")
		LoadScene.LoadMainMenu(null) # ← Added to prevent errors


@rpc("any_peer", "call_local")
func sync_queue_free_nodes(nodes: Array):
	queue_free_nodes = nodes.duplicate(true)
	apply_queued_deletions()
	emit_signal("queue_synced")


func _process(_delta: float) -> void:
	Steam.run_callbacks()

func apply_queued_deletions():
	await get_tree().process_frame

	for node in get_tree().get_nodes_in_group("Persistent"):
		if node.unique_id in queue_free_nodes:
			node.queue_free()
			print_role("Nodo eliminado por ID: " + node.unique_id)

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

	sync_queue_free_nodes.rpc(queue_free_nodes)

		
func remove_all_queue_free_nodes():
	if not multiplayer.is_server():
		return
		
	# Limpiar completamente la lista de nodos eliminados
	queue_free_nodes.clear()
	# Sincronizar la lista vacía con todos los clientes
	sync_queue_free_nodes.rpc(queue_free_nodes)



func UpnpSetup(Port):
	var upnp = UPNP.new();
	var discoverResult = upnp.discover();

	if (discoverResult == UPNP.UPNP_RESULT_SUCCESS):

		if (upnp.get_gateway() != null && upnp.get_gateway().is_valid_gateway()):
			upnp.add_port_mapping(Port, Port, "Godot_Game", "UDP");
			print_role("Puerto " + str(Port) + " mapeado en el router via UPNP.");
			print_role("La IP Pública es: " + PublicIp);
		else:
			print_role("UPNP: No se encontró un Gateway válido.");


	else:
		print_role("UPNP Discover falló con código: " + discoverResult);


func FetchPublicIp():

	var upnp = UPNP.new()
	
	# El descubrimiento es necesario para encontrar el Gateway (Router)
	var discoverResult = upnp.discover();

	if (discoverResult == UPNP.UPNP_RESULT_SUCCESS):
	
		if (upnp.get_gateway() != null && upnp.get_gateway().is_valid_gateway()):
		
			#Esta es la función clave que obtiene la IP externa
			PublicIp = upnp.query_external_address();
			print_role("IP Pública: " + PublicIp);
		
		else:
		
			print_role("UPNP: No se encontró un Gateway válido.");
		
	
	else:
	
		print_role("UPNP Discover falló con código: " + str(discoverResult));
		# Si falla el UPNP (por ejemplo, si el router lo tiene desactivado),
		# PublicIp se quedará vacía. Podrías poner una IP por defecto o manejar el error.
	

func FetchLocalIp():

	# Obtenemos todas las IPs de la máquina
	for Ip in IP.get_local_addresses():
	
		# Filtramos para quedarnos con la de la red local (típicamente 192.168.x.x)
		if Ip.begins_with("192.168.") or Ip.begins_with("10."):
			LocalIp = Ip
			print_role("IP Local: " + LocalIp)
			break	


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if steam_lobby_id != 0 and use_steam:
			Steam.leaveLobby(steam_lobby_id) # Avisar a Steam antes de morir
		# Ya no necesitamos SendUnregisterToMaster()[cite: 2]
		get_tree().quit()
