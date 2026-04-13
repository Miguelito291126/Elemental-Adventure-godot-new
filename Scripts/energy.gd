extends RigidBody2D

@onready var coinsound = $"coin sound"
@export var unique_id: String
var collected = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):	
		call_deferred("hide_coin")

func SaveGameData():
	var save_dict = {
		"filename": get_scene_file_path(),
		"parent": get_parent().get_path(),
		"pos_x": position.x, # Vector2 is not supported by JSON
		"pos_y": position.y,
		"collected": collected,
		"Name": name,
		"unique_id": unique_id
	}
	return save_dict

func _ready() -> void:
	add_to_group("Persistent")

	if unique_id == "" or unique_id == null:
		unique_id = str(get_path())

	await get_tree().process_frame

func hide_coin():
	if collected:
		return

	collected = !collected
	visible = false
	coinsound.play()
	
	
	if multiplayer.is_server():
		GamePersistentData.SavePersistentNodes()
		GameController.GameData.SaveGameData()

		GameController.getcoin.rpc()

		await coinsound.finished

		Network.add_queue_free_nodes(unique_id)
		Network.sync_queue_free_nodes.rpc(Network.queue_free_nodes)
