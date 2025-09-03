extends Node

@export var version = 9.5

@export var level = 1
@export var max_level = 18
@export var points = 0
@export var energys = 0
@export var character = "fire"
@export var available_elements = ["fire", "water", "air", "earth"]
@export var assigned_elements = {}  # peer_id : "element"

@export var port = 4444
@export var ip = "localhost"
var IsNetwork = false

var nodegame: Node
var levelnode: Node2D
var SpawnPoint: Node2D
var Multiplayerspawner: Array
var playernode: Node2D

var player_scene = preload("res://Scenes/player.tscn")

var multiplayerpeer : ENetMultiplayerPeer
var node_group = "Persistent"
	
const PATH := "user://data.cfg"
const PATH_2 := "user://data_state.cfg"
const PATH_3 := "user://config.cfg"
const DATA_SECTION := "Results"

func _ready() -> void:
	get_tree().get_multiplayer().server_disconnected.connect(MultiplayerServerDisconnected)
	get_tree().get_multiplayer().connected_to_server.connect(MultiplayerConnectionServerSucess)
	get_tree().get_multiplayer().connection_failed.connect(MultiplayerConnectionFailed)
	get_tree().get_multiplayer().peer_connected.connect(MultiplayerPlayerSpawner)
	get_tree().get_multiplayer().peer_disconnected.connect(MultiplayerPlayerRemover)
	
	LoadGameData()

func _exit_tree() -> void:
	get_tree().get_multiplayer().server_disconnected.disconnect(MultiplayerServerDisconnected)
	get_tree().get_multiplayer().connected_to_server.disconnect(MultiplayerConnectionServerSucess)
	get_tree().get_multiplayer().connection_failed.disconnect(MultiplayerConnectionFailed)
	get_tree().get_multiplayer().peer_connected.disconnect(MultiplayerPlayerSpawner)
	get_tree().get_multiplayer().peer_disconnected.disconnect(MultiplayerPlayerRemover)

	
func get_level_str() -> String:
	return "level_%d" % level
	
@rpc("any_peer", "call_local")
func assign_element(element: String):
	character = element
	print_role("Se te asignó el personaje:" + element)

@rpc("authority", "call_local")
func assign_element_to_player(peer_id: int):
	if peer_id in assigned_elements:
		# 👈 Ya tiene asignado antes, se reutiliza
		var element = assigned_elements[peer_id]
		assign_element.rpc_id(peer_id, element)
		return
	
	if available_elements.is_empty():
		print_role("No hay más elementos disponibles.")
		return
	
	var element = available_elements.pop_front()
	assigned_elements[peer_id] = element
	assign_element.rpc_id(peer_id, element)


@rpc("authority", "call_local")
func Remove_Element_Assigned(id: int) -> void:
	if assigned_elements.has(id):
		var element = assigned_elements[id]
		print_role("Jugador %d desconectado (personaje '%s' reservado)" % [id, element])
		# 👈 No devolvemos el elemento a available_elements
		# 👈 No borramos de assigned_elements

		

		

	
	
@rpc("any_peer", "call_local")
func getcoin():
	energys += 1
	
	SavePersistentNodes()
	SaveGameData()
	
	if IsNetwork:
		getpoint.rpc()
	else:
		getpoint()
		
	

@rpc("any_peer", "call_local")
func getpoint():
	points += 5
	
	SavePersistentNodes()
	SaveGameData()
	
@rpc("any_peer", "call_local")
func getlevel():
	level += 1
	
	SavePersistentNodes()
	SaveGameData()
	
	
	if IsNetwork:
		LoadVictoryMenu.rpc()
	else:
		LoadVictoryMenu()
	
	
	

	
@rpc("any_peer", "call_local")
func LoadGameOverMenu():
	load_scene_in_game_node("res://Scenes/game_over_menu.tscn")
	
@rpc("any_peer", "call_local")
func LoadVictoryMenu():
	
	DeletePersistentNodes()

	if level <= max_level:
		load_scene_in_game_node("res://Scenes/victory_menu.tscn")
	else:
		load_scene_in_game_node("res://Scenes/Super victory screen.tscn")
	
@rpc("any_peer", "call_local")
func LoadMainMenu():
	load_scene_in_game_node("res://Scenes/main_menu.tscn")
	
@rpc("any_peer", "call_local")
func LoadCharacterMenu():
	load_scene_in_game_node("res://Scenes/chose_character.tscn")
	
@rpc("any_peer", "call_local")
func load_level_scene():
	var scene_path = "res://Scenes/%s.tscn" % get_level_str()
	load_scene_in_game_node(scene_path)

@rpc("any_peer", "call_local")	
func load_scene_in_game_node(scene_path: String) -> void:
	# Solo elimina nodos con nombre que empieza por 'level_' o que coincidan con el nombre de la escena
	for child in nodegame.get_children():
		if child.name == "LevelSpawner" or child.name == "MultiplayerSpawner":
			continue  # <- en lugar de return
		
		child.queue_free()
	
	var scene = load(scene_path).instantiate()
	nodegame.add_child(scene)

@rpc("any_peer", "call_local")
func unload_scene_in_game_node() -> void:
	# Solo elimina nodos con nombre que empieza por 'level_' o que coincidan con el nombre de la escena
	for child in nodegame.get_children():
		if child.name == "LevelSpawner" or child.name == "MultiplayerSpawner":
			continue  # <- en lugar de return
		
		child.queue_free()
	
	
func print_role(msg: String):
	var is_server = get_tree().get_multiplayer().is_server()
	
	if is_server:
		# Azul
		print_rich("[color=blue][Servidor] " + msg + "[/color]")
	else:
		# Amarillo
		print_rich("[color=yellow][Cliente] " + msg + "[/color]")



func Play_MultiplayerServer():
	IsNetwork = true
	multiplayerpeer = ENetMultiplayerPeer.new()
	multiplayerpeer.create_server(port, 4)
	get_tree().get_multiplayer().multiplayer_peer = multiplayerpeer
	
	if get_tree().get_multiplayer().is_server():
		LoadCharacterMenu()
	
func Play_MultiplayerClient():
	IsNetwork = true
	multiplayerpeer = ENetMultiplayerPeer.new()
	multiplayerpeer.create_client(ip, port)
	get_tree().get_multiplayer().multiplayer_peer = multiplayerpeer

func MultiplayerPlayerSpawner(id: int = 1):

	if not get_tree().get_multiplayer().is_server():
		return
	

	assign_element_to_player(id)
	
	var player = player_scene.instantiate()
	player.name = str(id)
	player.id = player.name
	
	if levelnode and is_instance_valid(levelnode):
		levelnode.add_child(player, true)
		print_role("jugador Spawneado con el ID:" + str(id))
	else:
		print_role("jugador no Spawneado")
	

func MultiplayerPlayerRemover(id: int = 1):
	if not get_tree().get_multiplayer().is_server():
		return
	
	Remove_Element_Assigned(id)
	
	var player = null
	if levelnode and is_instance_valid(levelnode):
		player = levelnode.get_node_or_null(str(id))

	if player and is_instance_valid(player):
		player.queue_free()
		print_role("Jugador removido con el ID:" + str(id))
	else:
		print_role("Jugador No Valido Con el ID:" + str(id))

func MultiplayerConnectionFailed():
	print_role("Failed to connect to server")

	if multiplayerpeer:
		multiplayerpeer = null

	if IsNetwork:
		IsNetwork = false
	
	LoadMainMenu()
	
func MultiplayerConnectionServerSucess():
	print_role("Connected to server")
	
func MultiplayerServerDisconnected():
	print_role("Disconnecting from server...")
	
	if multiplayerpeer:
		multiplayerpeer = null

	if IsNetwork:
		IsNetwork = false
		
	LoadMainMenu()

func SingleplayerPlayerSpawner():
	var player = player_scene.instantiate()
	if levelnode and is_instance_valid(levelnode):
		levelnode.add_child(player, true)
		print_role("jugador Spawneado")
	else:
		print_role("jugador no Spawneado")
	

func SaveGameData():
	var config = ConfigFile.new()
	config.load(PATH)
	config.set_value(DATA_SECTION, "Coins", energys)
	config.set_value(DATA_SECTION, "Points", points)
	config.set_value(DATA_SECTION, "Level", level)
	config.save(PATH)
	
		
func LoadGameData():
	var config = ConfigFile.new()
	if config.load(PATH) == OK:
		energys = config.get_value(DATA_SECTION, "Coins", energys)
		points = config.get_value(DATA_SECTION, "Points", points)
		level = config.get_value(DATA_SECTION, "Level", level)
		
		
func LoadPersistentNodes():
	if not FileAccess.file_exists(PATH_2):
		return # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.
	var save_nodes = get_tree().get_nodes_in_group(node_group)
	for i in save_nodes:
		i.queue_free()

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open(PATH_2, FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Creates the helper class to interact with JSON.
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print_role("JSON Parse Error: " + json.get_error_message() + " in " + json_string + " at line " + str(json.get_error_line()))
			continue

		# Get the data from the JSON object.
		var node_data = json.data
		
		# ⚡ Saltar monedas recogidas o enemigos muertos
		if (node_data.has("collected") and node_data["collected"] == true) \
		or (node_data.has("death") and node_data["death"] == true):
			continue
			
		if node_data["filename"].ends_with("player.tscn"):
			continue

		# Firstly, we need to create the object and add it to the tree and set its position.
		var new_object = load(node_data["filename"]).instantiate()
		get_node(node_data["parent"]).add_child(new_object, true)
		new_object.position = Vector2(node_data["pos_x"], node_data["pos_y"])

		# Now we set the remaining variables.
		for i in node_data.keys():
			if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y":
				continue
			new_object.set(i, node_data[i])

		
func SavePersistentNodes():
	var save_file = FileAccess.open(PATH_2, FileAccess.WRITE)
	var save_nodes = get_tree().get_nodes_in_group(node_group)
	for node in save_nodes:
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.scene_file_path.is_empty():
			print_role("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		# Check the node has a save function.
		if !node.has_method("SaveGameData"):
			print_role("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("SaveGameData")
		
		# ⛔ Evitar guardar nulos
		if node_data == null:
			print_role("Node '%s' returned null on SaveGameData(), skipped" % node.name)
			continue
			
		# JSON provides a static method to serialized JSON string.
		var json_string = JSON.stringify(node_data)

		# Store the save dictionary as a new line in the save file.
		save_file.store_line(json_string)

func DeletePersistentNodes():
	if FileAccess.file_exists(PATH_2):
		DirAccess.remove_absolute(PATH_2)
		
func DeleteData():
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)

	if FileAccess.file_exists(PATH_2):
		DirAccess.remove_absolute(PATH_2)

	if FileAccess.file_exists(PATH_3):
		DirAccess.remove_absolute(PATH_3)

