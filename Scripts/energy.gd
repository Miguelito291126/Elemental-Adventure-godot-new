extends RigidBody2D
@export var collected := false
@onready var coinsound = $"coin sound"

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):	
		call_deferred("hide_coin")

func SaveGameData():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"collected" : collected
	}
	return save_dict

func hide_coin():
	if not visible:
		return

	coinsound.play()
	visible = false
	collected = true

	if not multiplayer.is_server():
		return

	GameController.getcoin.rpc()

	GamePersistentData.SavePersistentNodes()
	GameController.GameData.SaveGameData()

	await coinsound.finished

	Network.add_queue_free_nodes(get_path())
	Network.sync_queue_free_nodes.rpc(Network.queue_free_nodes)
	Network.remove_node_synced.rpc(get_path())
