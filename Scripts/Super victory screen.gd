extends Control

@onready var energys = $Panel/VBoxContainer2/energys
@onready var score = $Panel/VBoxContainer2/score
@onready var level = $Panel/VBoxContainer2/level

func _enter_tree() -> void:
	set_multiplayer_authority(multiplayer.get_unique_id())

func _ready() -> void:
	GameController.victory_menu = self
	
	level.text = str("You completed level: ",  GameController.level - 1, " you WON!!")
	score.text = str("Score: ",  GameController.points)
	energys.text = str("Energys: ", GameController.energys)

func _on_back_pressed() -> void:
	if !is_multiplayer_authority():
		return

	GameController.GameData.DeleteResource()
	GamePersistentData.DeletePersistentNodes()
	Network.close_conection()

