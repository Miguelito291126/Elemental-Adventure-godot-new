extends Node

@export var level = 1
@export var points = 0
@export var energys = 0
@export var character = "fire"
@export var available_elements = ["fire", "water", "air", "earth"]
@export var assigned_elements = {}  # peer_id : "element"
@export var valid_coin_ids = []
@export var valid_hearths_ids = []
@export var valid_enemies_ids = []

@export var port = 4444
@export var ip = "localhost"
var IsNetwork = false
var IsMaster = true
var IsInLevel = false

var nodegame: Node
var levelnode: Node2D
var spawner: Node2D
var playernode: Node2D

var multiplayerpeer : MultiplayerPeer = OfflineMultiplayerPeer.new()
var node_group = "Persistent"
	
const PATH := "user://data.cfg"
const PATH_2 := "user://data_state.cfg"
const DATA_SECTION := "Results"

func _ready() -> void:
	LoadGameData()
	
func get_level_str() -> String:
	return "level_%d" % level
	
@rpc("any_peer", "call_local")
func assign_element(element: String):
	GameController.character = element
	print("Se te asignó el personaje:", element)

@rpc("authority", "call_local")
func assign_element_to_player(peer_id: int):
	if peer_id in assigned_elements:
		return  # Ya tiene asignado
	
	if available_elements.is_empty():
		print("No hay más elementos disponibles.")
		return
	
	var element = available_elements.pop_front()
	assigned_elements[peer_id] = element
	assign_element.rpc_id(peer_id, element)

@rpc("authority", "call_local")
func Remove_Element_Assigned(id: int) -> void:
	if assigned_elements.has(id):
		var element = assigned_elements[id]
		print("Liberando personaje '%s' del jugador ID %d" % [element, id])
		
		# Devuelve el personaje a la lista
		if not available_elements.has(element):
			available_elements.append(element)
		
		assigned_elements.erase(id)
		

		

	
	
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
	IsInLevel = false
	load_scene_in_game_node("res://Scenes/game_over_menu.tscn")
	
@rpc("any_peer", "call_local")
func LoadVictoryMenu():
	IsInLevel = false
	
	DeletePersistentNodes()
	
	if level < 24:
		load_scene_in_game_node("res://Scenes/victory_menu.tscn")
	else:
		load_scene_in_game_node("res://Scenes/Super victory screen.tscn")
	
@rpc("any_peer", "call_local")
func LoadMainMenu():
	if IsNetwork:
		IsNetwork = false
		IsMaster = true
		multiplayerpeer.close()
	
	IsInLevel = false

	load_scene_in_game_node("res://Scenes/main_menu.tscn")
	
@rpc("any_peer", "call_local")
func LoadCharacterMenu():
	IsInLevel = false
	load_scene_in_game_node("res://Scenes/chose_character.tscn")
	
@rpc("any_peer", "call_local")
func load_level_scene():
	IsInLevel = true
	var scene_path = "res://Scenes/%s.tscn" % get_level_str()
	load_scene_in_game_node(scene_path)
	
func load_scene_in_game_node(scene_path: String) -> void:
	# Solo elimina nodos con nombre que empieza por 'level_' o que coincidan con el nombre de la escena
	for child in nodegame.get_children():
		if child.name == "MultiplayerSpawner":
			continue  # <- en lugar de return
		
		child.queue_free()
	
	var scene = load(scene_path).instantiate()
	nodegame.add_child(scene)
	
func Play_MultiplayerServer():
	IsNetwork = true
	IsMaster = true
	multiplayerpeer = ENetMultiplayerPeer.new()
	multiplayerpeer.create_server(port, 4)
	get_tree().get_multiplayer().multiplayer_peer = multiplayerpeer
	
	if !get_tree().get_multiplayer().is_server():
		return
			
	LoadCharacterMenu()
	
func Play_MultiplayerClient():
	IsNetwork = true
	IsMaster = false
	multiplayerpeer = ENetMultiplayerPeer.new()
	multiplayerpeer.create_client(ip, port)
	get_tree().get_multiplayer().multiplayer_peer = multiplayerpeer
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SavePersistentNodes()
		SaveGameData()
	
	
func SaveGameData():
	var config = ConfigFile.new()
	if config.load(PATH) == OK:
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
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
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
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		# Check the node has a save function.
		if !node.has_method("SaveGameData"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("SaveGameData")
		
		# ⛔ Evitar guardar nulos
		if node_data == null:
			print("Node '%s' returned null on SaveGameData(), skipped" % node.name)
			continue
			
		# JSON provides a static method to serialized JSON string.
		var json_string = JSON.stringify(node_data)

		# Store the save dictionary as a new line in the save file.
		save_file.store_line(json_string)

func DeletePersistentNodes():
	if FileAccess.file_exists(PATH_2):
		DirAccess.remove_absolute(PATH_2)
		
func DeleteData():
	var config = ConfigFile.new()
	config.clear()
	config.save("user://config.cfg")
	config.save("user://data.cfg")
	
	DeletePersistentNodes()
