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


func _ready() -> void:
	if IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return

	var config = ConfigFile.new()
	config.load("user://data.cfg")
	energys = config.get_value("data", "coin", 0)
	level = config.get_value("data", "level", 1)
	points = config.get_value("data", "points", 0)
		

@rpc("any_peer", "call_local")
func getcoin():
	energys += 1
	
	if IsNetwork:
		getpoint.rpc()
	else:
		getpoint()
		
	if IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return
		
	var config = ConfigFile.new()
	config.load("user://data.cfg")
	config.set_value("data", "coin", energys)
	config.save("user://data.cfg")

@rpc("any_peer", "call_local")
func getpoint():
	points += 5
	
	if IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return
	
	var config = ConfigFile.new()
	config.load("user://data.cfg")
	config.set_value("data", "points", points)
	config.save("user://data.cfg")
	
@rpc("any_peer", "call_local")
func getlevel():
	level += 1
	
	if IsNetwork:
		LoadVictoryMenu.rpc()
	else:
		LoadVictoryMenu()
	
	if IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return
	
	var config = ConfigFile.new()
	config.load("user://data.cfg")
	config.set_value("data", "level", level)
	config.save("user://data.cfg")
	

	
@rpc("any_peer", "call_local")
func LoadGameOverMenu():
	IsInLevel = false
	load_scene_in_game_node("res://Scenes/game_over_menu.tscn")
	
@rpc("any_peer", "call_local")
func LoadVictoryMenu():
	IsInLevel = false
	
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
	

	
