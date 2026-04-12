extends RigidBody2D
@export var collected := false
@onready var coinsound = $"coin sound"

@export var unique_id: String

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):	
		call_deferred("hide_coin")

func SaveGameData():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"collected" : collected,
		"unique_id": unique_id
	}
	return save_dict

func _ready() -> void:
	add_to_group("Persistent")

	if unique_id == "" or unique_id == null:
		randomize()
		unique_id = str(Time.get_unix_time_from_system()) + "_" + str(randi())

	await get_tree().process_frame

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

	Network.add_queue_free_nodes(unique_id)
	Network.sync_queue_free_nodes.rpc(Network.queue_free_nodes)
	queue_free()
