extends Control

@onready var energys = $Panel/VBoxContainer2/energys
@onready var score = $Panel/VBoxContainer2/score
@onready var level = $Panel/VBoxContainer2/level
@onready var back_button = $Panel/VBoxContainer/back
@onready var restart_button = $Panel/VBoxContainer/restart

func _ready() -> void:
	GameController.victory_menu = self

	if not OS.has_feature("dedicated_server"):
		# Deshabilitar el botón Play para clientes
		if not multiplayer.is_server():
			restart_button.disabled = true
			restart_button.text = "Wait..."
	
	level.text = str("You completed level: ",  GameController.level - 1, " you WON!!")
	score.text = str("Score: ",  GameController.points)
	energys.text = str("Energys: ", GameController.energys)

func _on_back_pressed() -> void:
	GameController.GameData.DeleteData()
	GamePersistentData.DeletePersistentNodes()

	Network.close_conection()
	queue_free()

func _on_restart_pressed() -> void:
	if not OS.has_feature("dedicated_server"):
		# Solo el servidor puede presionar Play
		if not multiplayer.is_server():
			return

	delete_data_2.rpc()

@rpc("any_peer", "call_local")
func delete_data_2():
	GameController.GameData.DeleteData()
	GamePersistentData.DeletePersistentNodes()

	LoadScene.load_level_scene(GameController.levelnode)
	queue_free()

