extends CanvasLayer

@onready var energys = $VBoxContainer2/energys
@onready var score = $VBoxContainer2/score
@onready var level = $VBoxContainer2/level


func _ready() -> void:
	level.text = str("You completed: ",  GameController.level - 1)
	score.text = str("Score: ",  GameController.points)
	energys.text = str("Energys: ", GameController.energys) # ← Cambiado a energys real

func _on_back_pressed() -> void:
	GameController.DeletePersistentNodes()
	GameController.LoadMainMenu()

func _on_next_pressed() -> void:
	if GameController.IsNetwork:
		if get_tree().get_multiplayer().is_server():
			GameController.load_level_scene.rpc()
	else:
		GameController.load_level_scene()
