extends Node2D

@onready var spawnpoint = $spawner
@onready var Playersspawner = $PlayersSpawner

func _ready() -> void:
	GameController.levelnode = self
	GameController.SpawnPoint = spawnpoint
	Network.Multiplayerspawner.append(Playersspawner)
	
	GamePersistentData.LoadPersistentNodes()

	Network.print_role("Nivel Iniciado")

	if multiplayer.is_server():
		if not OS.has_feature("dedicated_server"):
			Network.MultiplayerPlayerSpawner(multiplayer.get_unique_id())

		for id in multiplayer.get_peers():
			Network.MultiplayerPlayerSpawner(id)



