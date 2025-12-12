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
	"Character Menu": "res://Scenes/chose_character.tscn",
	"Main Menu": "res://Scenes/main_menu.tscn",
	"Game Over": "res://Scenes/game_over_menu.tscn",
	"Victory Menu": "res://Scenes/victory_menu.tscn",
	"Super Victory Menu": "res://Scenes/Super victory screen.tscn",
}

var loading_screen_path: String = "res://Scenes/loading_screen.tscn"
var loading_screen = load(loading_screen_path)
var loader_resource: PackedScene
var scene_path: String
var progress: Array = []

var use_sub_theads: bool = false

func load_scene(current_scene = null, next_scene = null):

	if next_scene != null:
		scene_path = next_scene

	var loading_screen_intance = loading_screen.instantiate()
	GameController.nodegame.add_child(loading_screen_intance)
	
	self.progress_changed.connect(loading_screen_intance.update_progress_bar)
	self.load_done.connect(loading_screen_intance.fade_out_loading_screen)

	await Signal(loading_screen_intance, "safe_to_load")

	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()
	else:
		Network.print_role("No current scene to free")

	if GAME_SCENE.has(scene_path):
		scene_path = GAME_SCENE[scene_path]
	else:
		scene_path = scene_path
	
	var loader_next_scene = ResourceLoader.load_threaded_request(scene_path, "", use_sub_theads)
	if loader_next_scene == OK:
		Network.print_role("loading...")
		set_process(true)


func _process(_delta):
	var load_status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	match load_status:
		0:
			Network.print_role("failed to load: invalid resource")
			set_process(false)
			return
		2:
			Network.print_role("failed to load")
			set_process(false)
			return
		1:
			emit_signal("progress_changed", progress[0] * 100)
		3:
			Network.print_role("Completed")
			
			if scene_path == "res://Scenes/game.tscn":
				return

			var new_scene = ResourceLoader.load_threaded_get(scene_path).instantiate()
			if is_instance_valid(new_scene):
				GameController.nodegame.add_child(new_scene)
			
			emit_signal("progress_changed", 1.0)
			emit_signal("load_done")
			set_process(false)


func get_level_str() -> String:
	return "level_%d" % GameController.level

func LoadGameOverMenu(current_scene = null):
	LoadScene.load_scene(current_scene, "res://Scenes/game_over_menu.tscn")

func LoadVictoryMenu(current_scene = null):
	GamePersistentData.DeletePersistentNodes()
	
	if GameController.level <= GameController.max_level:
		LoadScene.load_scene(current_scene, "res://Scenes/victory_menu.tscn")
	else:
		LoadScene.load_scene(current_scene, "res://Scenes/Super victory screen.tscn")


func LoadMainMenu(current_scene = null):
	LoadScene.load_scene(current_scene, "res://Scenes/main_menu.tscn")


func LoadCharacterMenu(current_scene = null):
	# Verificar si la escena de elegir personaje ya está cargada
	if GameController.chose_characters and is_instance_valid(GameController.chose_characters):
		# La escena ya está cargada, no cargar de nuevo
		return

	LoadScene.load_scene(current_scene, "res://Scenes/chose_character.tscn")


func load_level_scene(current_scene = null):
	var scene_path = "res://Scenes/%s.tscn" % get_level_str()
	LoadScene.load_scene(current_scene, scene_path)
