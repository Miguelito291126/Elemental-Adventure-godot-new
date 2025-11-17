extends Node2D

@onready var spawnpoint = $spawner
@onready var Playersspawner = $PlayersSpawner

@export var GameData: DataResource = DataResource.LoadGameData()

func _ready() -> void:
	GameController.levelnode = self
	GameController.SpawnPoint = spawnpoint
	Network.Multiplayerspawner.append(Playersspawner)
	
	GamePersistentData.LoadPersistentNodes()

	if Network.IsNetwork :

		Network.print_role("Nivel Iniciado")

		if get_tree().get_multiplayer().is_server():
			if not OS.has_feature("dedicated_server"):
				Network.MultiplayerPlayerSpawner(get_tree().get_multiplayer().get_unique_id())

			for id in get_tree().get_multiplayer().get_peers():
				Network.MultiplayerPlayerSpawner(id)


	else:
		GameController.SingleplayerPlayerSpawner()
