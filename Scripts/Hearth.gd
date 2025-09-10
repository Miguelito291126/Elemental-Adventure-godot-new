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
		if Network.IsNetwork:
			hide_hearth.rpc(body)
		else:
			hide_hearth(body)


@rpc("any_peer", "call_local")
func hide_hearth(body: Node2D):
	if visible:
		if body != null and body.has_method("healting"):
			body.healting(1)

		hearthsound.play()
		visible = false
		collected = true
		GameData.SavePersistentNodes()
		GameData.SaveGameData()
		await hearthsound.finished
		queue_free()
