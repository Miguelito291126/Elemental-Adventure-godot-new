extends CanvasLayer

@onready  var energys = $VBoxContainer2/energys
@onready  var score = $VBoxContainer2/score
@onready var level = $level


func _enter_tree() -> void:
	if GameController.IsNetwork:
		set_multiplayer_authority(get_tree().get_multiplayer().get_unique_id())
	
func _ready() -> void:
	level.text = str("You completed level: ",  GameController.level - 1, " you WON!!")
	score.text = str("Score: ",  GameController.points)
	energys.text = str("Energys: ", GameController.energys)

func _on_back_pressed() -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return

		GameController.DeleteResources()
		GameController.DeletePersistentNodes()
		GameController.multiplayerpeer.close()
	else:
		GameController.DeleteResources()
		GameController.DeletePersistentNodes()
		GameController.LoadMainMenu()
	
