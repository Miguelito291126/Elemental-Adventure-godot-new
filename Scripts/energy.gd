extends RigidBody2D
@export var collected := false
@onready var coinsound = $"coin sound"

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):	
		if Network.IsNetwork:
			hide_coin.rpc()
		else:
			hide_coin()

func SaveGameData():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"collected" : collected
	}
	return save_dict


@rpc("any_peer", "call_local")
func hide_coin():
	if visible:
		coinsound.play()
		GameController.getcoin()
		visible = false
		collected = true
		GameData.SavePersistentNodes()
		GameData.SaveGameData()

		Network.add_queue_free_nodes(self.get_path())

		await coinsound.finished
		queue_free()
