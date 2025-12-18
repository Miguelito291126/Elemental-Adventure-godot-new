extends Node

var node_group = "Persistent"

const PATH := "user://data_state.cfg"
const DATA_SECTION := "Results"

func LoadPersistentNodes():

	if not multiplayer.is_server():
		return

	if not FileAccess.file_exists(PATH):
		return # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.

	# 🔹 Limpiar nodos persistentes existentes (solo una vez al inicio)
	var save_nodes = get_tree().get_nodes_in_group(node_group)
	for i in save_nodes:
		Network.add_queue_free_nodes(i.get_path())
		Network.sync_queue_free_nodes.rpc(Network.queue_free_nodes)
		Network.remove_node_synced.rpc(i.get_path())

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open(PATH, FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Creates the helper class to interact with JSON.
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			Network.print_role("JSON Parse Error: " + json.get_error_message() + " in " + json_string + " at line " + str(json.get_error_line()))
			continue

		# Get the data from the JSON object.
		var node_data = json.data
		
		# ⚡ Saltar monedas recogidas o enemigos muertos
		if (node_data.has("collected") and node_data["collected"] == true) \
		or (node_data.has("death") and node_data["death"] == true):
			continue

		if not node_data.has("filename"):
			return

		var parent_node = get_node(node_data["parent"])
		var new_object = load(node_data["filename"]).instantiate()

		if is_instance_valid(new_object) and is_instance_valid(parent_node):
			parent_node.add_child(new_object, true)
			new_object.position = Vector2(node_data["pos_x"], node_data["pos_y"])

		for i in node_data.keys():
			if i in ["filename", "parent", "pos_x", "pos_y"]:
				continue
			new_object.set(i, node_data[i])


func SavePersistentNodes():
	if not multiplayer.is_server():
		return

	var save_file = FileAccess.open(PATH, FileAccess.WRITE)
	var save_nodes = get_tree().get_nodes_in_group(node_group)
	for node in save_nodes:
		if node.scene_file_path.is_empty() or !node.has_method("SaveGameData"):
			continue
		
		var node_data = node.call("SaveGameData")
		if node_data == null:
			continue
		
		save_file.store_line(JSON.stringify(node_data))


func DeletePersistentNodes():
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)

func DeleteData():
	DeletePersistentNodes()
	GameController.GameData.DeleteResource()