extends RigidBody2D
@export var collected := false
@onready var hearthsound = $"hearth sound"

func SaveGameData():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"collected" : collected
	}
	return save_dict

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		hide_hearth.rpc(body.name)



@rpc("any_peer", "call_local")
func hide_hearth(player_name: String):
	if visible:
		var players = get_tree().get_nodes_in_group("player")
		for player in players:
			if player.name == player_name:
				player.healting(1)

		hearthsound.play()
		visible = false
		collected = true

		if multiplayer.is_server():
			GamePersistentData.SavePersistentNodes()
			GameController.GameData.SaveGameData()
		
		Network.add_queue_free_nodes(get_path())
		
		await hearthsound.finished

		Network.remove_node_synced.rpc(get_path())
