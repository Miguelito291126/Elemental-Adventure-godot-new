extends CanvasLayer

@onready  var energys = $VBoxContainer2/energys
@onready  var score = $VBoxContainer2/score

func _ready() -> void:
	score.text = str("Score: ",  GameController.points)
	energys.text = str("Energys: ", GameController.points)

func _on_back_pressed() -> void:
	if GameController.IsNetwork:
		if get_tree().get_multiplayer().is_server():
			GameController.LoadMainMenu.rpc()
	else:
		GameController.LoadMainMenu()
	
