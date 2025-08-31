extends Node

@onready var LevelSpawner = $LevelSpawner

func _ready() -> void:
	GameController.nodegame = self
	GameController.Multiplayerspawner.append(LevelSpawner)
