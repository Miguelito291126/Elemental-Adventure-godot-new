extends Control

@onready var energys = $Panel/VBoxContainer2/energys
@onready var score = $Panel/VBoxContainer2/score
@onready var level = $Panel/VBoxContainer2/level
@onready var next_button = $Panel/VBoxContainer/next

func _ready() -> void:
	GameController.victory_menu = self

	# Deshabilitar el botón Play para clientes
	if not multiplayer.is_server():
		next_button.disabled = true
		next_button.text = "Wait..."
	
	level.text = str("You completed level: ",  GameController.level - 1, " you WON!!")
	score.text = str("Score: ",  GameController.points)
	energys.text = str("Energys: ", GameController.energys)

func _on_back_pressed() -> void:
	# Solo el servidor puede presionar Play
	if not multiplayer.is_server():
		return

	delete_data.rpc()
	Network.close_conection()

@rpc("any_peer", "call_local")
func delete_data():
	GameController.GameData.DeleteData()
	GamePersistentData.DeletePersistentNodes()
