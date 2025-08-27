extends Node2D

var player = preload("res://Scenes/player.tscn")
@onready var spawnpoint = $spawner
@onready var World = $World

func _ready() -> void:
	GameController.levelnode = self
	GameController.spawner = spawnpoint
	
	GameController.LoadPersistentNodes()

	if GameController.IsNetwork :
		get_tree().get_multiplayer().peer_connected.connect(MultiplayerPlayerSpawner)
		get_tree().get_multiplayer().peer_disconnected.connect(MultiplayerPlayerRemover)
		
		if get_tree().get_multiplayer().is_server():
			for id in get_tree().get_multiplayer().get_peers():
				MultiplayerPlayerSpawner(id)
				
			var my_id = get_tree().get_multiplayer().get_unique_id()
				
			if not OS.has_feature("dedicated_server") and not get_tree().get_multiplayer().get_peers().has(my_id):
				MultiplayerPlayerSpawner(1)
			

	else:
		SingleplayerPlayerSpawner()

				
func _exit_tree() -> void:
	get_tree().get_multiplayer().peer_connected.disconnect(MultiplayerPlayerSpawner)
	get_tree().get_multiplayer().peer_disconnected.disconnect(MultiplayerPlayerRemover)

func MultiplayerPlayerSpawner(id: int = 1):

	await get_tree().create_timer(0.5).timeout
	
	GameController.assign_element_to_player(id)
	
	await get_tree().create_timer(1).timeout
	
	var player = player.instantiate()
	player.global_position = spawnpoint.global_position
	player.name = str(id)
	player.id = player.name
	add_child(player, true)
	
	print("jugador Spawneado con el ID:", id)

	

func MultiplayerPlayerRemover(id: int = 1):
	await get_tree().create_timer(1).timeout
	
	GameController.Remove_Element_Assigned(id)
	
	var player = get_node_or_null(str(id))
	if player and is_instance_valid(player):
		player.queue_free()
		print("Jugador removido con el ID:", id)


func SingleplayerPlayerSpawner():
	var playerinstanciate = player.instantiate()
	playerinstanciate.global_position = spawnpoint.global_position
	add_child(playerinstanciate)

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node.is_in_group("player"):
		print("Spawn Jugador con id:", node.name)
		node.global_position = spawnpoint.global_position
		node.id = node.name


func _on_multiplayer_spawner_despawned(node: Node) -> void:
	print("Despawneando Nodo:", node.name)
	node.queue_free()
