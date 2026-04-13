extends Node

var node_group = "Persistent"

const PATH := "user://data_state.cfg"
var is_loading = false
var is_saving = false

func LoadPersistentNodes():
	if not multiplayer.is_server():
		return

	if not FileAccess.file_exists(PATH):
		Network.print_role("No hay archivo de guardado, manteniendo nivel original.")
		return

	if is_loading:
		return

	is_loading = true

	Network.queue_free_nodes.clear()

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open(PATH, FileAccess.READ)
	var removed_ids = {} # IDs que vienen en el archivo pero no están vivos (por ejemplo, monedas recogidas o enemigos muertos)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if not parse_result == OK: continue

		# Get the data from the JSON object.
		var node_data = json.data
		var uid = node_data["unique_id"]
		
		# Saltar monedas recogidas o enemigos muertos
		if (node_data.has("collected") and node_data["collected"] == true) or \
				(node_data.has("death") and node_data["death"] == true):
					Network.add_queue_free_nodes(uid)
					removed_ids[uid] = true
					continue

		var parent_node = get_tree().get_root().get_node_or_null(node_data["parent"])
		# ... (tu lógica de instanciación actual) ...
		if is_instance_valid(parent_node):
			# Intenta encontrar si el nodo ya existe en la escena para no duplicarlo
			var existing = get_tree().get_nodes_in_group(node_group).filter(func(n): return n.unique_id == uid)
			if existing.size() > 0:
				existing[0].position = Vector2(node_data["pos_x"], node_data["pos_y"])
			else:
				var new_object = load(node_data["filename"]).instantiate()
				parent_node.add_child(new_object, true)
				new_object.position = Vector2(node_data["pos_x"], node_data["pos_y"])
				new_object.unique_id = uid

	Network.sync_queue_free_nodes.rpc(Network.queue_free_nodes)

	# Limpieza local en el servidor
	var current_nodes = get_tree().get_nodes_in_group(node_group)
	for node in current_nodes:
		if removed_ids.has(node.unique_id):
			node.queue_free()

	is_loading = false





func SavePersistentNodes():
	if is_saving:
		return

	is_saving = true

	if not multiplayer.is_server():
		return

	var all_data = {}
	if FileAccess.file_exists(PATH):
		var read_file = FileAccess.open(PATH, FileAccess.READ)
		while read_file.get_position() < read_file.get_length():
			var line = read_file.get_line()
			var json = JSON.parse_string(line)
			if json:
				all_data[json["unique_id"]] = json

	var save_nodes = get_tree().get_nodes_in_group(node_group)
	for node in save_nodes:
		if node.has_method("SaveGameData"):
			var node_data = node.call("SaveGameData")
			if node_data:
				all_data[node_data["unique_id"]] = node_data

	var save_file = FileAccess.open(PATH, FileAccess.WRITE)
	for id in all_data:
		save_file.store_line(JSON.stringify(all_data[id]))

	is_saving = false


func DeletePersistentNodes():
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)
