extends Node

var data_path = "user://Game_Data/Data.json"
var directory = "Game_Data"
var data = {}

func _ready():
	load_file()

#setting saver
func save_file():
	print("Creating data file")
	data = {
		"settings":{
			"master_volume": Globals.master_volume, 
			"fx_volume":  Globals.fx_volume, 
			"music_volume":  Globals.music_volume, 
			"fullscreen":  Globals.fullscreen, 
			"resolution":  Globals.resolution, 
			"initial_time":  Globals.initial_time, 
			"time_speed":  Globals.time_speed,
			"autosave":  Globals.autosave,
			"autosave_length":  Globals.autosave_length,
			"use_keyboard": Globals.use_keyboard,
			"use_mobile_buttons": Globals.use_mobile_buttons,
			"Graphics": Globals.Graphics,
			"FPS": Globals.FPS,
			"Vsync": Globals.Vsync,
		},
		"time":{
			"day": Globals.day,
			"hour": Globals.hour,
			"minute":Globals.minute,
			"time": Globals.time,
		},
		"players":{
			"level": Globals.level,
			"level_int": Globals.level_int,
			"num_players": Globals.num_players,
		},
		"Network":{
			"username": Network.username,
			"ip": Network.ip,
			"port": Network.port,
		}
	}

	var dir = DirAccess.open("user://")
	dir.make_dir(directory)
	
	var datafile = FileAccess.open(data_path, FileAccess.WRITE)
	datafile.store_line(JSON.stringify(data))
	
	Signals.finish_add_data.emit()
	print("finish")

func load_file():
	print("loading data...")
	var datafile = FileAccess.open(data_path, FileAccess.READ)
	if not datafile or not FileAccess.file_exists(data_path):
		print("Data file doesn't exist!")
		return
	
	if datafile.get_length() <= 0:
		print("State data file empty!")
		return
		
	print("Data file found")
	while datafile.get_position() < datafile.get_length():
		var json_string = datafile.get_line()

		var json = JSON.new()

		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		data = json.get_data()

		var settings = data.settings
		
		#settings
		Globals.master_volume = settings.master_volume
		Globals.fx_volume = settings.fx_volume
		Globals.music_volume = settings.music_volume
		Globals.fullscreen = settings.fullscreen
		Globals.resolution = str_to_var("Vector2i" + settings.resolution)
		Globals.initial_time = settings.initial_time
		Globals.time_speed = settings.time_speed
		Globals.autosave = settings.autosave
		Globals.autosave_length = settings.autosave_length
		Globals.use_mobile_buttons = settings.use_mobile_buttons
		Globals.use_keyboard = settings.use_keyboard
		Globals.Graphics = settings.Graphics
		Globals.Vsync = settings.Vsync
		Globals.FPS = settings.FPS

		var time = data.time

		Globals.day = time.day
		Globals.hour = time.hour
		Globals.minute = time.minute
		Globals.time = time.time
		
		var players = data.players

		Globals.num_players = players.num_players
		Globals.level = players.level
		Globals.level_int = players.level_int

		var network = data.Network
		Network.username = network.username
		Network.ip = network.ip
		Network.port = network.port
		Network.lisenerport = network.port + 1
		Network.broadcasterport = network.port + 2
		
		Signals.finish_load_data.emit()
	
	print("finish")
	
func remove_file():
	print("Removing file...")
	if FileAccess.file_exists(data_path):
		DirAccess.remove_absolute(data_path)
		data.clear()
	
	
	Signals.finish_remove_data.emit()
	print("finish")
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not Globals.level == "level_31":
			save_file()
		else:
			remove_file()

func load_volume(bus, value):
	
	match bus:
		0:
			Globals.master_volume = value
		1:
			Globals.music_volume = value
		2:
			Globals.fx_volume = value
			
	AudioServer.set_bus_volume_db(bus, value)

	if value <= -45:
		AudioServer.set_bus_mute(bus,true)
	else: 
		AudioServer.set_bus_mute(bus,false)
	
	save_file()
	
func load_fullscreen(value):
	if value == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	Globals.fullscreen = value
	save_file()
	
func load_resolution(value):
	DisplayServer.window_set_size(value)
	get_viewport().set_size(value)
	Globals.resolution = value
	save_file()

func load_inputs(value):
	Globals.use_keyboard = value

	for i in range(Globals.num_players):
		Globals._clear_inputs_player(i)
	
	for i in range(Globals.num_players):
		Globals._inputs_player(i)


	save_file()

func load_initial_time(value):
	var minutes_per_day = 1440
	var minutes_per_hour = 60
	var ingame_to_real_minute_duration = (2 * PI) / minutes_per_day
	Globals.initial_time = int(value)
	Globals.time = ingame_to_real_minute_duration * Globals.initial_time * minutes_per_hour
	save_file()

func load_graphics(value):
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", value)
	ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", value)
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality.mobile", value)
	ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality.mobile", value)

	if value == 0:
		ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size", 1096)
		ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size.mobile", 998)
	elif value == 1:
		ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size",  2048)
		ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size.mobile", 1096)
	elif value == 2:	
		ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size",  4096)
		ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size.mobile", 2048)
	elif value == 3:
		ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size",  8048)
		ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size.mobile", 4096)
	elif value == 4:
		ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size",  10096)
		ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size.mobile", 8048)
		
	Globals.Graphics = value
	save_file()

