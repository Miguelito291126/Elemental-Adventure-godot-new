extends CanvasLayer

@onready var energys = $VBoxContainer2/energys
@onready var score = $VBoxContainer2/score
@onready var level = $VBoxContainer2/level

func _enter_tree() -> void:
	if Network.IsNetwork:
		set_multiplayer_authority(get_tree().get_multiplayer().get_unique_id())

func _ready() -> void:
	GameController.victory_menu = self

	level.text = str("You completed level: ",  GameController.level - 1)
	score.text = str("Score: ",  GameController.points)
	energys.text = str("Energys: ", GameController.energys) # ← Cambiado a energys real

func _on_back_pressed() -> void:
	if Network.IsNetwork:
		if !is_multiplayer_authority():
			return

		Network.multiplayerpeer.close()
	else:
		LoadScene.LoadMainMenu(self)

@rpc("any_peer", "call_local")
func unload_current_scene():
	UnloadScene.unload_scene(self)

func _on_next_pressed() -> void:
	if Network.IsNetwork:
		if !is_multiplayer_authority():
			return

		unload_current_scene.rpc()
	else:
		LoadScene.load_level_scene(self)
