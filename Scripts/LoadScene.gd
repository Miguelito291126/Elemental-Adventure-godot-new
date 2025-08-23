extends Node

signal progress_changed(progress)
signal load_done

const GAME_SCENE ={
	"level_1": "res://Scenes/level_1.tscn", 
	"level_2": "res://Scenes/level_2.tscn",
	"level_3": "res://Scenes/level_3.tscn",
	"level_4": "res://Scenes/level_4.tscn",
	"level_5": "res://Scenes/level_5.tscn",
	"level_6": "res://Scenes/level_6.tscn", 
	"level_7": "res://Scenes/level_7.tscn",
	"level_8": "res://Scenes/level_8.tscn",
	"level_9": "res://Scenes/level_9.tscn",
	"level_10": "res://Scenes/level_10.tscn",
	"level_11": "res://Scenes/level_11.tscn",
	"level_12": "res://Scenes/level_12.tscn",
	"level_13": "res://Scenes/level_13.tscn",
	"level_14": "res://Scenes/level_14.tscn",
	"level_15": "res://Scenes/level_15.tscn",
	"level_16": "res://Scenes/level_16.tscn",
	"level_17": "res://Scenes/level_17.tscn",
	"level_18": "res://Scenes/level_18.tscn",
	"level_19": "res://Scenes/level_19.tscn",
	"level_20": "res://Scenes/level_20.tscn",
	"level_21": "res://Scenes/level_21.tscn",
	"level_22": "res://Scenes/level_22.tscn",
	"level_23": "res://Scenes/level_23.tscn",
	"level_24": "res://Scenes/level_24.tscn",
	"level_25": "res://Scenes/level_25.tscn",
	"level_26": "res://Scenes/level_26.tscn",
	"level_27": "res://Scenes/level_27.tscn",
	"level_28": "res://Scenes/level_28.tscn",
	"level_29": "res://Scenes/level_29.tscn",
	"level_30": "res://Scenes/level_30.tscn",
	"level_31": "res://Scenes/level_31.tscn",
	"map_1": "res://Scenes/map_1.tscn",
}

var loading_screen_path: String = "res://Scenes/loading_screen.tscn"
var loading_screen = load(loading_screen_path)
var loader_resource: PackedScene
var scene_path: String
var progress: Array = []

var use_sub_theads: bool = false

func _ready():
	load_scene(null, "res://Scenes/main_menu.tscn")


func load_scene(current_scene, next_scene):

	if next_scene != null:
		scene_path = next_scene

	var loading_screen_intance = loading_screen.instantiate()
	get_tree().get_root().get_node("Game").add_child(loading_screen_intance)
	
	self.progress_changed.connect(loading_screen_intance.update_progress_bar)
	self.load_done.connect(loading_screen_intance.fade_out_loading_screen)

	await Signal(loading_screen_intance, "safe_to_load")

	if current_scene != null:
		if is_instance_valid(current_scene):
			current_scene.queue_free()

	if GAME_SCENE.has(scene_path):
		scene_path = GAME_SCENE[scene_path]
	else:
		scene_path = scene_path
	
	var loader_next_scene = ResourceLoader.load_threaded_request(scene_path, "", use_sub_theads)
	if loader_next_scene == OK:
		set_process(true)


func _process(_delta):
	var load_status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	match load_status:
		0,2:
			print("failed to load")
			set_process(false)
			return
		1:
			emit_signal("progress_changed", progress[0])
		3:
			
			if scene_path == "res://Scenes/game.tscn":
				pass
			else:
				var new_scene = ResourceLoader.load_threaded_get(scene_path).instantiate()
				get_tree().get_root().get_node("Game").add_child(new_scene, true)


			emit_signal("progress_changed", 1.0)
			emit_signal("load_done")
			set_process(false)
