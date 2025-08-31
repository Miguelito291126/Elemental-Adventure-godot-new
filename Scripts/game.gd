extends Node

@onready var Multiplayerspawner = $MultiplayerSpawner

func _ready() -> void:
	GameController.nodegame = self
	GameController.Multiplayerspawner.append(Multiplayerspawner)
