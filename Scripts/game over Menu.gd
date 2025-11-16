extends Control

@onready var energys = $Panel/VBoxContainer2/energys
@onready var score = $Panel/VBoxContainer2/score


func _enter_tree() -> void:
	if Network.IsNetwork:
		set_multiplayer_authority(get_tree().get_multiplayer().get_unique_id())

func _ready() -> void:
	GameController.game_over_menu = self

	score.text = str("Score: ",  GameController.points)
	energys.text = str("Energys: ", GameController.energys) # ← Cambiado a energys real

# Botón volver al menú
func _on_back_pressed() -> void:
	if Network.IsNetwork:
		if !is_multiplayer_authority():
			return
			
		Network.multiplayerpeer.close()
	else:
		LoadScene.LoadMainMenu(self)

@rpc("any_peer", "call_local")
func load_level_scene():
	LoadScene.load_level_scene(self)

# Botón volver al nivel actual
func _on_return_pressed() -> void:
	if Network.IsNetwork:
		if !is_multiplayer_authority():
			return

		load_level_scene.rpc()
	else:
		LoadScene.load_level_scene(self)
