extends CanvasLayer

@onready  var energys = $VBoxContainer2/energys
@onready  var score = $VBoxContainer2/score

func _enter_tree() -> void:
	if GameController.IsNetwork:
		set_multiplayer_authority(get_tree().get_multiplayer().get_unique_id())
	
func _ready() -> void:
	score.text = str("Score: ",  GameController.points)
	energys.text = str("Energys: ", GameController.points)

func _on_back_pressed() -> void:
	GameController.DeleteData()
	get_tree().quit()
	
