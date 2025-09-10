extends Node

@onready var LevelSpawner = $LevelSpawner

func _ready() -> void:
	GameController.nodegame = self
	Network.Multiplayerspawner.append(LevelSpawner)

	LoadScene.LoadMainMenu(null)
