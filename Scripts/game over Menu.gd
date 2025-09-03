extends CanvasLayer

func _enter_tree() -> void:
	if GameController.IsNetwork:
		set_multiplayer_authority(get_tree().get_multiplayer().get_unique_id())

func return_to_menu():
	GameController.DeletePersistentNodes()
	GameController.LoadMainMenu()

# Botón volver al menú
func _on_back_pressed() -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
			
		GameController.multiplayerpeer.close()
	else:
		GameController.LoadMainMenu()

# Botón volver al nivel actual
func _on_return_pressed() -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return


		GameController.load_level_scene.rpc()
	else:
		GameController.load_level_scene()
