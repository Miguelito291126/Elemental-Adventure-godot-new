extends Node

func _ready() -> void:
	GameController.nodegame = self
	LoadScene.LoadMainMenu(null)
