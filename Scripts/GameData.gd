extends Node

var node_group = "Persistent"
	
const PATH := "user://data.cfg"
const PATH_2 := "user://data_state.cfg"
const PATH_3 := "user://config.cfg"
const DATA_SECTION := "Results"

func _ready() -> void:
	LoadGameData()

func SaveGameData():
	if Network.IsNetwork:
		if not get_tree().get_multiplayer().is_server():
			return

	var config = ConfigFile.new()
	config.load(PATH)
	config.set_value(DATA_SECTION, "Coins", GameController.energys)
	config.set_value(DATA_SECTION, "Points", GameController.points)
	config.set_value(DATA_SECTION, "Level", GameController.level)
	config.save(PATH)
	
		
func LoadGameData():
	if Network.IsNetwork:
		if not get_tree().get_multiplayer().is_server():
			return

	var config = ConfigFile.new()
	if config.load(PATH) == OK:
		GameController.energys = config.get_value(DATA_SECTION, "Coins", GameController.energys)
		GameController.points = config.get_value(DATA_SECTION, "Points", GameController.points)
		GameController.level = config.get_value(DATA_SECTION, "Level", GameController.level)


func LoadPersistentNodes():
	if Network.IsNetwork:
		if not get_tree().get_multiplayer().is_server():
			return

	if not FileAccess.file_exists(PATH_2):
		return # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.

	# 🔹 Limpiar nodos persistentes existentes (solo una vez al inicio)
	if Network.IsNetwork:
		DeleteNodes.rpc()
	else:
		DeleteNodes()

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open(PATH_2, FileAccess.READ)
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


		_create_persistent_node(node_data)

@rpc("authority", "call_local")
func DeleteNodes():
	var save_nodes = get_tree().get_nodes_in_group(node_group)
	for i in save_nodes:
		i.queue_free()

@rpc("authority", "call_local") # clientes y servidor pueden llamar, pero se ejecuta local
func _create_persistent_node(node_data: Dictionary):
	if not node_data.has("filename"):
		return

	var new_object = load(node_data["filename"]).instantiate()
	get_node(node_data["parent"]).add_child(new_object, true)
	new_object.position = Vector2(node_data["pos_x"], node_data["pos_y"])

	for i in node_data.keys():
		if i in ["filename", "parent", "pos_x", "pos_y"]:
			continue
		new_object.set(i, node_data[i])

func SavePersistentNodes():
	if Network.IsNetwork:
		if not get_tree().get_multiplayer().is_server():
			return

	var save_file = FileAccess.open(PATH_2, FileAccess.WRITE)
	var save_nodes = get_tree().get_nodes_in_group(node_group)
	for node in save_nodes:
		if node.scene_file_path.is_empty() or !node.has_method("SaveGameData"):
			continue
		
		var node_data = node.call("SaveGameData")
		if node_data == null:
			continue
		
		save_file.store_line(JSON.stringify(node_data))


func DeleteResources():
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)

func DeletePersistentNodes():
	if FileAccess.file_exists(PATH_2):
		DirAccess.remove_absolute(PATH_2)


func DeleteConfig():
	if FileAccess.file_exists(PATH_3):
		DirAccess.remove_absolute(PATH_3)
		
func DeleteData():
	DeleteResources()
	DeletePersistentNodes()
	DeleteConfig()
