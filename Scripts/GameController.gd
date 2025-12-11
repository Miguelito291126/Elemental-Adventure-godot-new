extends Node

var version = ProjectSettings.get_setting("application/config/version")
var gamename = ProjectSettings.get_setting("application/config/name")
var credits = "Miguelito2911"

@export var max_level = 24
@export var energys = 0
@export var points = 0
@export var level = 1

var nodegame: Node
var levelnode: Node2D
var SpawnPoint: Node2D
var playernode: Node2D
var main_menu: Control
var game_over_menu: Control
var pause_menu: CanvasLayer
var victory_menu: Control
var chose_characters: CanvasLayer

@export var GameData: DataResource = DataResource.LoadGameData()

var player_scene = preload("res://Scenes/player.tscn")

func _ready():
	energys = GameData.energys
	points = GameData.points
	level = GameData.level

@rpc("any_peer", "call_local")
func getcoin():
	energys += 1

	GamePersistentData.SavePersistentNodes()
	GameData.SaveGameData()
	
	getpoint.rpc()

		
	

@rpc("any_peer", "call_local")
func getpoint():
	points += 5

	GamePersistentData.SavePersistentNodes()
	GameData.SaveGameData()

@rpc("any_peer", "call_local")
func load_victory_scene():
	LoadScene.LoadVictoryMenu(levelnode)
	
@rpc("any_peer", "call_local")
func getlevel():
	level += 1

	GamePersistentData.DeletePersistentNodes()
	Network.remove_all_queue_free_nodes()
	GameData.SaveGameData()
	
	load_victory_scene.rpc()
