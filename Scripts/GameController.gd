extends Node

var version = ProjectSettings.get_setting("application/config/version")

@export var level = 1
@export var max_level = 24
@export var points = 0
@export var energys = 0

var nodegame: Node
var levelnode: Node2D
var SpawnPoint: Node2D
var playernode: Node2D
var main_menu: CanvasLayer
var game_over_menu: CanvasLayer
var pause_menu: CanvasLayer
var victory_menu: CanvasLayer


var player_scene = preload("res://Scenes/player.tscn")



@rpc("any_peer", "call_local")
func getcoin():
	energys += 1

	GameData.SavePersistentNodes()
	GameData.SaveGameData()
	
	if Network.IsNetwork:
		getpoint.rpc()
	else:
		getpoint()
		
	

@rpc("any_peer", "call_local")
func getpoint():
	points += 5

	GameData.SavePersistentNodes()
	GameData.SaveGameData()

@rpc("any_peer", "call_local")
func load_victory_scene():
	LoadScene.LoadVictoryMenu(GameController.levelnode)
	
@rpc("any_peer", "call_local")
func getlevel():
	level += 1

	GameData.DeletePersistentNodes()
	GameData.SaveGameData()

	if Network.IsNetwork:
		load_victory_scene.rpc()
	else:
		LoadScene.LoadVictoryMenu(GameController.levelnode)
	


func SingleplayerPlayerSpawner():
	var player = player_scene.instantiate()
	if levelnode and is_instance_valid(levelnode):
		levelnode.add_child(player, true)
		Network.print_role("jugador Spawneado")
	else:
		Network.print_role("jugador no Spawneado")




