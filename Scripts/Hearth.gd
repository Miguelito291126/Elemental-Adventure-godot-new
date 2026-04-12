extends RigidBody2D
@export var collected := false
@onready var hearthsound = $"hearth sound"
@export var unique_id: String

func SaveGameData():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"collected" : collected,
		"unique_id" : unique_id
	}
	return save_dict

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		call_deferred("hide_hearth", body.name)

func _ready() -> void:
	add_to_group("Persistent")

	if unique_id == "" or unique_id == null:
		randomize()
		unique_id = str(Time.get_unix_time_from_system()) + "_" + str(randi())

	await get_tree().process_frame

func hide_hearth(player_name: String) -> void:
	if not visible:
		return

	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.name == player_name:
			# Asegúrate de que el método se llame exactamente así en el script del jugador
			player.healting(1)

	hearthsound.play()
	visible = false
	collected = true

	if not multiplayer.is_server():
		return

	GamePersistentData.SavePersistentNodes()
	GameController.GameData.SaveGameData()

	await hearthsound.finished

	Network.add_queue_free_nodes(unique_id)
	Network.sync_queue_free_nodes.rpc(Network.queue_free_nodes)
	queue_free()
