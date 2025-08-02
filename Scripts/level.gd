extends Node2D

var player = preload("res://Scenes/player.tscn")
@onready var spawnpoint = $SpawnPoint
@onready var World = $World
@onready var Spawner = $MultiplayerSpawner

func _ready() -> void:
	GameController.levelnode = self
	GameController.spawner = spawnpoint

	if GameController.IsNetwork :
		if !get_tree().get_multiplayer().is_server():
			return
		
		get_tree().get_multiplayer().peer_connected.connect(MultiplayerPlayerSpawner)
		get_tree().get_multiplayer().peer_disconnected.connect(MultiplayerPlayerRemover)
		
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
	if !get_tree().get_multiplayer().is_server():
		return

	if has_node(str(id)):
		print("El jugador con ID %d ya existe. No se instancia de nuevo." % id)
		return
	
	await get_tree().create_timer(0.5).timeout

	print("jugador Spawneado con el ID:", id)
	
	GameController.assign_element_to_player(id)
	
	var playerinstanciate = player.instantiate()
	playerinstanciate.global_position = spawnpoint.global_position
	playerinstanciate.name = str(id)
	add_child(playerinstanciate, true)
	

func MultiplayerPlayerRemover(id: int = 1):
	if !get_tree().get_multiplayer().is_server():
		return
	
	if !has_node(str(id)):
		return
	
	GameController.Remove_Element_Assigned(id)
		
	get_node(str(id)).queue_free()
	
	print("Jugador removido con el ID:", id)


func SingleplayerPlayerSpawner():
	var playerinstanciate = player.instantiate()
	playerinstanciate.global_position = spawnpoint.global_position
	add_child(playerinstanciate)


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if !node.is_in_group("player"):
		return
	
	print("Spawn Jugador con id:", node.name)
	node.global_position = spawnpoint.global_position


func _on_multiplayer_spawner_despawned(node: Node) -> void:
	print("Despawneando Nodo:", node.name)
	node.queue_free()
