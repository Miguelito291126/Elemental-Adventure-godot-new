extends Node

var data_state_path = "user://Node_Data/Data.json"
var directory = "Node_Data"
var node_group ="persistent"
var node_data = {}

func save_file_state():
	print("Creating state data file")

	var dir = DirAccess.open("user://")
	dir.make_dir(directory)

	var datafile = FileAccess.open(data_state_path, FileAccess.WRITE)

	var save_nodes = get_tree().get_nodes_in_group(node_group)
	for node in save_nodes:
		
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue
		if !node.has_method("save_state"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		datafile.store_line(JSON.stringify(node.save_state()))
	
	Signals.finish_add_data.emit()
	print("finish")

func load_file_state():
	print("loading state data...")
	
	var datafile = FileAccess.open(data_state_path, FileAccess.READ)
	
	if not datafile or not FileAccess.file_exists(data_state_path):
		print("State data file doesn't exist!")
		return

	if datafile.get_length() <= 0:
		print("State data file empty!")
		return
	
	print("data state file found")
	
	var save_nodes = get_tree().get_nodes_in_group(node_group)
	
	for i in save_nodes:
		i.queue_free()

	while datafile.get_position() < datafile.get_length():
		var json_string = datafile.get_line()
		
		var json = JSON.new()
		
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		var parse_result_str = json.parse_string(json_string)
		var json_data = json.get_data()
		var node_data_file = node_data.size()
		
		node_data[node_data_file] = json_data

		if not node_data[node_data_file].filename == "res://Scenes/player.tscn":
			var new_object = load(node_data[node_data_file].filename).instantiate()

			print("creating node '%s'" % new_object.name)
			
			if get_node(node_data[node_data_file].parent) != null:
				get_node(node_data[node_data_file].parent).add_child(new_object)
			else:
				print("fixing the parent...")
				node_data[node_data_file].parent = "/root/Game/" + Globals.level
				
				if get_node(node_data[node_data_file].parent) != null:
					get_node(node_data[node_data_file].parent).add_child(new_object)
				else:
					print("fixing the parent again...")
					node_data[node_data_file].parent = "/root/Game/level_" + str(Globals.level_int)
					if get_node(node_data[node_data_file].parent) != null:
						get_node(node_data[node_data_file].parent).add_child(new_object)
					else:
						print("null parent of object '%s'" % new_object.name)
			

			new_object.load_state(node_data[node_data_file])

	print("finish")
	Signals.finish_load_data.emit()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not Network.is_networking:
			if not Globals.level == "level_31":
				save_file_state()
			else:
				remove_state_file()
		
func remove_state_file():
	if FileAccess.file_exists(data_state_path):
		DirAccess.remove_absolute(data_state_path)
		node_data.clear()
	Signals.finish_remove_data.emit()
	
	
func autosave_logic():
	var time_passed = Time.get_unix_time_from_system() - int(Globals.autosaver_start_time)
		
	if (time_passed > (int(Globals.autosave_length) * 60)) :
		if not Network.is_networking:
			save_file_state()
			Data.save_file()
			Globals.autosaver_start_time = str(Time.get_unix_time_from_system())
