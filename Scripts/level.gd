extends Node2D

@onready var spawnpoint = $spawner


func _ready() -> void:
	GameController.levelnode = self
	GameController.SpawnPoint = spawnpoint

	if multiplayer.is_server():

		await get_tree().process_frame

		GamePersistentData.LoadPersistentNodes()

		await get_tree().create_timer(0.3).timeout

		if not OS.has_feature("dedicated_server"):
			Network.MultiplayerPlayerSpawner()

		for id in multiplayer.get_peers():
			Network.MultiplayerPlayerSpawner(id)

	Network.print_role("Nivel Iniciado")
