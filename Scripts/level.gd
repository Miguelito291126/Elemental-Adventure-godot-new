extends Node2D

@onready var spawnpoint = $spawner
@onready var Playersspawner = $PlayersSpawner

func _ready() -> void:
	GameController.levelnode = self
	GameController.SpawnPoint = spawnpoint
	GameController.Multiplayerspawner.append(Playersspawner)
	
	GameController.LoadPersistentNodes()

	if GameController.IsNetwork :
		if get_tree().get_multiplayer().is_server():
			for id in get_tree().get_multiplayer().get_peers():
				GameController.MultiplayerPlayerSpawner(id)
			
			if not OS.has_feature("dedicated_server"):
				GameController.MultiplayerPlayerSpawner(get_tree().get_multiplayer().get_unique_id())
	else:
		GameController.SingleplayerPlayerSpawner()
