extends CanvasLayer


func return_to_menu():
	GameController.LoadMainMenu()

# Botón volver al menú
func _on_back_pressed() -> void:
	GameController.LoadMainMenu()

# Botón volver al nivel actual
func _on_return_pressed() -> void:
	if GameController.IsNetwork:
		if get_tree().get_multiplayer().is_server():
			GameController.load_level_scene.rpc()
	else:
		GameController.load_level_scene()
