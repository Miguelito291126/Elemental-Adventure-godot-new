extends Node

#level
var level = "level_1"
var level_node
var level_int = 1

#time
var minute = 00
var day = 0
var hour = 12
var time = 0.0

#others
var num_players = 1
var player_index = 0

var player_name: Array = [
	"Fire",
	"Water",
	"Air",
	"Earth",
]
var player_color: Array = [
	"white",
	"blue",
	"gray",
	"green",
]

var ball_color: Array = [
	"orange",
	"blue",
	"gray",
	"green",
]

var alpha = 1.0 # build

var player_color_dict: Dictionary = {
	0: Color(player_color[0], alpha), # color, alpha
	1: Color(player_color[1], alpha), # color, alpha
	2: Color(player_color[2], alpha), # color, alpha
	3: Color(player_color[3], alpha), # color, alpha
}

var ball_color_dict: Dictionary = {
	0: Color(ball_color[0], alpha), # color, alpha
	1: Color(ball_color[1], alpha), # color, alpha
	2: Color(ball_color[2], alpha), # color, alpha
	3: Color(ball_color[3], alpha), # color, alpha
}

#player
var last_position = null
var max_deaths = 5
var max_hearths = 5

var player: Dictionary = {
	0: null, 
	1: null, 
	2: null, 
	3: null, 
}

var energys: Dictionary = {
	0: 0, 
	1: 0, 
	2: 0, 
	3: 0, 
}
var score: Dictionary = {
	0: 0, 
	1: 0, 
	2: 0, 
	3: 0, 
}
var hearths: Dictionary = {
	0: max_hearths, 
	1: max_hearths, 
	2: max_hearths, 
	3: max_hearths, 
}
var deaths: Dictionary = {
	0: 0, 
	1: 0, 
	2: 0, 
	3: 0, 
}



var actions_items: Array[String]

func check_duplicates(a):
	var is_dupe = false
	var found_dupe = false 

	for i in range(a.size()):
		if is_dupe == true:
			break
		for j in range(a.size()):
			if a[j] == a[i] && i != j:
				is_dupe = true
				found_dupe = true
				print("duplicate")
				break 

	return is_dupe

func get_duplicates(a):
	if a.size() < 2:
		return []
	
	var seen = {}
	seen[a[0]] = true
	var duplicate_indexes = []
	
	for i in range(1, a.size()):
		var v = a[i]
		if seen.has(v):
			# Duplicate!
			duplicate_indexes.append(i)
		else:
			seen[v] = true
	
	return duplicate_indexes

func array_unique(a):
	var unique: Array = []
	for b in a:
		if not unique.has(b):
			unique.append(b)

	return unique


func remove_duplicates(a):
	for i in range(a.size()):
		for j in range(a.size()):
			if a[j] == a[i] && i != j:
				a.remove_at(j)

#settings
var master_volume = 0 
var fx_volume = 0
var music_volume = 0
var fullscreen = false
var resolution = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
var initial_time = 12
var time_speed = 1.0
var autosave = true
var autosave_length = 5
var autosaver_start_time = 0
var Graphics = 0
var use_mobile_buttons = OS.get_name() == "Android" or OS.get_name() == "iOS"
var use_keyboard = OS.get_name() == "Windows" or OS.get_name() == "Linux" or OS.get_name() == "Web"
var FPS = false
var Vsync = false


func _clear_inputs_player(player_index):

	if not use_keyboard:
		
		var right_action: String
		var right_action_event: InputEventJoypadMotion

		var left_action: String
		var left_action_event: InputEventJoypadMotion
		
		var jump_action: String
		var jump_action_event: InputEventJoypadButton
		
		var shot_action: String
		var shot_action_event: InputEventJoypadButton
		
		var pause_action: String
		var pause_action_event: InputEventJoypadButton

		var down_action: String
		var down_action_event: InputEventJoypadMotion
	
		right_action = "right{n}".format({"n":player_index})
		
		if InputMap.has_action(right_action):

			InputMap.erase_action(right_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			right_action_event = InputEventJoypadMotion.new()
			right_action_event.device = player_index
			right_action_event.axis = JOY_AXIS_LEFT_X # <---- horizontal axis
			right_action_event.axis_value =  1.0 # <---- right
			InputMap.action_erase_event(right_action, right_action_event)
		
		
		left_action = "left{n}".format({"n":player_index})

		if InputMap.has_action(left_action):

		
			InputMap.erase_action(left_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			left_action_event = InputEventJoypadMotion.new()
			left_action_event.device = player_index
			left_action_event.axis = JOY_AXIS_LEFT_X # <---- horizontal axis
			left_action_event.axis_value =  -1.0 # <---- right
			InputMap.action_erase_event(left_action, left_action_event)
		
		shot_action = "shoot{n}".format({"n":player_index})

		if InputMap.has_action(shot_action):
			InputMap.erase_action(shot_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			shot_action_event = InputEventJoypadButton.new()
			shot_action_event.device = player_index
			shot_action_event.button_index = JOY_BUTTON_X
			InputMap.action_erase_event(shot_action, shot_action_event)
		
		pause_action = "pause{n}".format({"n":player_index})

		if not InputMap.has_action(pause_action):
			InputMap.erase_action(pause_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			pause_action_event = InputEventJoypadButton.new()
			pause_action_event.device = player_index
			pause_action_event.button_index = JOY_BUTTON_START
			InputMap.action_erase_event(pause_action, pause_action_event)

		down_action = "down{n}".format({"n":player_index})
		if InputMap.has_action(down_action):
			InputMap.erase_action(down_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			down_action_event = InputEventJoypadMotion.new()
			down_action_event.device = player_index
			down_action_event.axis = JOY_AXIS_LEFT_Y # <---- vertical axis
			down_action_event.axis_value = 1.0 # <---- down
			InputMap.action_erase_event(down_action, down_action_event)
		
		jump_action = "jump{n}".format({"n":player_index})
		if InputMap.has_action(jump_action):
			InputMap.erase_action(jump_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			jump_action_event = InputEventJoypadButton.new()
			jump_action_event.device = player_index
			jump_action_event.button_index = JOY_BUTTON_A
			InputMap.action_erase_event(jump_action, jump_action_event)

		actions_items.clear()
	else:
		
		var wasd: Dictionary = {
			"key_right": KEY_D,
			"key_left":  KEY_A,
			"key_jump":  KEY_SPACE,
			"key_down":  KEY_S,
			"key_shoot":  KEY_W,
			"key_pause": KEY_ESCAPE,
			}
		var arrows: Dictionary = {
			"key_right": KEY_RIGHT,
			"key_left":  KEY_LEFT,
			"key_jump":  KEY_SPACE,
			"key_down":  KEY_DOWN,
			"key_shoot":  KEY_UP,
			"key_pause": KEY_ESCAPE,
			}
		var hjkl: Dictionary = {
			"key_right": KEY_L,
			"key_left":  KEY_H,
			"key_jump":  KEY_SPACE,
			"key_down":  KEY_J,
			"key_shoot":  KEY_K,
			"key_pause": KEY_ESCAPE,
			}
		var uiop: Dictionary = {
			"key_right": KEY_P,
			"key_left":  KEY_U,
			"key_jump":  KEY_SPACE,
			"key_down":  KEY_I,
			"key_shoot":  KEY_O,
			"key_pause": KEY_ESCAPE,
			}
		var keymaps: Dictionary = {
			0: wasd,
			1: arrows,
			2: hjkl,
			3: uiop,
			}

		var right_action: String
		var right_action_event: InputEventKey

		var left_action: String
		var left_action_event: InputEventKey
		
		var jump_action: String
		var jump_action_event: InputEventKey
		
		var shot_action: String
		var shot_action_event: InputEventKey

		var pause_action: String
		var pause_action_event: InputEventKey

		var down_action: String
		var down_action_event: InputEventKey



		right_action = "right{n}".format({"n":player_index})

		if InputMap.has_action(right_action):
			InputMap.erase_action(right_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			right_action_event = InputEventKey.new()
			right_action_event.keycode = keymaps[player_index]["key_right"]
			InputMap.action_erase_event(right_action, right_action_event)



		left_action = "left{n}".format({"n":player_index})

		if InputMap.has_action(left_action):
			InputMap.erase_action(left_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			left_action_event = InputEventKey.new()
			left_action_event.keycode = keymaps[player_index]["key_left"]
			InputMap.action_erase_event(left_action, left_action_event)
		
		jump_action = "jump{n}".format({"n":player_index})

		if InputMap.has_action(jump_action):
			
			InputMap.erase_action(jump_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			jump_action_event = InputEventKey.new()
			jump_action_event.keycode = keymaps[player_index]["key_jump"]
			InputMap.action_erase_event(jump_action, jump_action_event)
		
		shot_action = "shoot{n}".format({"n":player_index})
		
		if InputMap.has_action(shot_action):
			InputMap.erase_action(shot_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			shot_action_event = InputEventKey.new()
			shot_action_event.keycode = keymaps[player_index]["key_shoot"]
			InputMap.action_erase_event(shot_action, shot_action_event)

		pause_action = "pause{n}".format({"n":player_index})
		
		if InputMap.has_action(pause_action):
			InputMap.erase_action(pause_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			pause_action_event = InputEventKey.new()
			pause_action_event.keycode = keymaps[player_index]["key_pause"]
			InputMap.action_erase_event(pause_action, pause_action_event)

		down_action = "down{n}".format({"n":player_index})
		if InputMap.has_action(down_action):
			InputMap.erase_action(down_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			down_action_event = InputEventKey.new()
			down_action_event.keycode = keymaps[player_index]["key_down"]
			InputMap.action_erase_event(down_action, down_action_event)

		jump_action = "jump{n}".format({"n":player_index})
		if InputMap.has_action(jump_action):
			InputMap.erase_action(jump_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			jump_action_event = InputEventKey.new()
			jump_action_event.keycode = keymaps[player_index]["key_jump"]
			InputMap.action_erase_event(jump_action, jump_action_event)

		actions_items.clear()

func _inputs_player(player_index):

	if not use_keyboard:
		
		var right_action: String
		var right_action_event: InputEventJoypadMotion

		var left_action: String
		var left_action_event: InputEventJoypadMotion
		
		var jump_action: String
		var jump_action_event: InputEventJoypadButton
		
		var shot_action: String
		var shot_action_event: InputEventJoypadButton
		
		var pause_action: String
		var pause_action_event: InputEventJoypadButton

		var down_action: String
		var down_action_event: InputEventJoypadMotion
	
		right_action = "right{n}".format({"n":player_index})
		
		if not InputMap.has_action(right_action):

			InputMap.add_action(right_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			right_action_event = InputEventJoypadMotion.new()
			right_action_event.device = player_index
			right_action_event.axis = JOY_AXIS_LEFT_X # <---- horizontal axis
			right_action_event.axis_value =  1.0 # <---- right
			InputMap.action_add_event(right_action, right_action_event)
		
		
		left_action = "left{n}".format({"n":player_index})

		if not InputMap.has_action(left_action):

		
			InputMap.add_action(left_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			left_action_event = InputEventJoypadMotion.new()
			left_action_event.device = player_index
			left_action_event.axis = JOY_AXIS_LEFT_X # <---- horizontal axis
			left_action_event.axis_value =  -1.0 # <---- right
			InputMap.action_add_event(left_action, left_action_event)
		
		shot_action = "shoot{n}".format({"n":player_index})

		if not InputMap.has_action(shot_action):
			InputMap.add_action(shot_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			shot_action_event = InputEventJoypadButton.new()
			shot_action_event.device = player_index
			shot_action_event.button_index = JOY_BUTTON_X
			InputMap.action_add_event(shot_action, shot_action_event)
		
		pause_action = "pause{n}".format({"n":player_index})

		if not InputMap.has_action(pause_action):
			InputMap.add_action(pause_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			pause_action_event = InputEventJoypadButton.new()
			pause_action_event.device = player_index
			pause_action_event.button_index = JOY_BUTTON_START
			InputMap.action_add_event(pause_action, pause_action_event)

		down_action = "down{n}".format({"n":player_index})
		if not InputMap.has_action(down_action):
			InputMap.add_action(down_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			down_action_event = InputEventJoypadMotion.new()
			down_action_event.device = player_index
			down_action_event.axis = JOY_AXIS_LEFT_Y # <---- vertical axis
			down_action_event.axis_value = 1.0 # <---- down
			InputMap.action_add_event(down_action, down_action_event)
		
		jump_action = "jump{n}".format({"n":player_index})
		if not InputMap.has_action(jump_action):
			InputMap.add_action(jump_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			jump_action_event = InputEventJoypadButton.new()
			jump_action_event.device = player_index
			jump_action_event.button_index = JOY_BUTTON_A
			InputMap.action_add_event(jump_action, jump_action_event)
		
			
		actions_items.append(left_action)
		actions_items.append(shot_action)
		actions_items.append(right_action)
		actions_items.append(pause_action)
		actions_items.append(down_action)
		actions_items.append(jump_action)
		

		
	else:
		
		var wasd: Dictionary = {
			"key_right": KEY_D,
			"key_left":  KEY_A,
			"key_jump":  KEY_SPACE,
			"key_down":  KEY_S,
			"key_shoot":  KEY_W,
			"key_pause": KEY_ESCAPE,
			}
		var arrows: Dictionary = {
			"key_right": KEY_RIGHT,
			"key_left":  KEY_LEFT,
			"key_jump":  KEY_SPACE,
			"key_down":  KEY_DOWN,
			"key_shoot":  KEY_UP,
			"key_pause": KEY_ESCAPE,
			}
		var hjkl: Dictionary = {
			"key_right": KEY_L,
			"key_left":  KEY_H,
			"key_jump":  KEY_SPACE,
			"key_down":  KEY_J,
			"key_shoot":  KEY_K,
			"key_pause": KEY_ESCAPE,
			}
		var uiop: Dictionary = {
			"key_right": KEY_P,
			"key_left":  KEY_U,
			"key_jump":  KEY_SPACE,
			"key_down":  KEY_I,
			"key_shoot":  KEY_O,
			"key_pause": KEY_ESCAPE,
			}
		var keymaps: Dictionary = {
			0: wasd,
			1: arrows,
			2: hjkl,
			3: uiop,
			}

		var right_action: String
		var right_action_event: InputEventKey

		var left_action: String
		var left_action_event: InputEventKey
		
		var jump_action: String
		var jump_action_event: InputEventKey
		
		var shot_action: String
		var shot_action_event: InputEventKey

		var pause_action: String
		var pause_action_event: InputEventKey

		var down_action: String
		var down_action_event: InputEventKey



		right_action = "right{n}".format({"n":player_index})

		if not InputMap.has_action(right_action):
			InputMap.add_action(right_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			right_action_event = InputEventKey.new()
			right_action_event.keycode = keymaps[player_index]["key_right"]
			InputMap.action_add_event(right_action, right_action_event)



		left_action = "left{n}".format({"n":player_index})

		if not InputMap.has_action(left_action):
			InputMap.add_action(left_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			left_action_event = InputEventKey.new()
			left_action_event.keycode = keymaps[player_index]["key_left"]
			InputMap.action_add_event(left_action, left_action_event)
		
		jump_action = "jump{n}".format({"n":player_index})

		if not InputMap.has_action(jump_action):
			
			InputMap.add_action(jump_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			jump_action_event = InputEventKey.new()
			jump_action_event.keycode = keymaps[player_index]["key_jump"]
			InputMap.action_add_event(jump_action, jump_action_event)
		
		shot_action = "shoot{n}".format({"n":player_index})
		
		if not InputMap.has_action(shot_action):
			InputMap.add_action(shot_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			shot_action_event = InputEventKey.new()
			shot_action_event.keycode = keymaps[player_index]["key_shoot"]
			InputMap.action_add_event(shot_action, shot_action_event)

		pause_action = "pause{n}".format({"n":player_index})
		
		if not InputMap.has_action(pause_action):
			InputMap.add_action(pause_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			pause_action_event = InputEventKey.new()
			pause_action_event.keycode = keymaps[player_index]["key_pause"]
			InputMap.action_add_event(pause_action, pause_action_event)

		down_action = "down{n}".format({"n":player_index})
		if not InputMap.has_action(down_action):
			InputMap.add_action(down_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			down_action_event = InputEventKey.new()
			down_action_event.keycode = keymaps[player_index]["key_down"]
			InputMap.action_add_event(down_action, down_action_event)

		jump_action = "jump{n}".format({"n":player_index})
		if not InputMap.has_action(jump_action):
			InputMap.add_action(jump_action)
			# Creat a new InputEvent instance to assign to the InputMap.
			jump_action_event = InputEventKey.new()
			jump_action_event.keycode = keymaps[player_index]["key_jump"]
			InputMap.action_add_event(jump_action, jump_action_event)
			
		actions_items.append(left_action)
		actions_items.append(shot_action)
		actions_items.append(right_action)
		actions_items.append(pause_action)
		actions_items.append(down_action)
		actions_items.append(jump_action)
