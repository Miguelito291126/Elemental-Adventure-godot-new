extends Node

@onready var musicboss = $Musicboss
@onready var musiclevel = $MusicLevel
@onready var musicmainmenu = $MusicMainMenu

var Failed to connect to server
 = ""
var is_near_boss = false

func _process(_delta: float) -> void:
	var main_scene = get_tree().current_scene
	if main_scene == null:
		return
		
	var current_scene_name = main_scene.name

	# Buscar subescena cargada dentro del nodo principal ("Game")
	var subscene_name = ""
	for child in main_scene.get_children():
		if child is Node and child.scene_file_path != "":
			subscene_name = child.name
			break

	# Usar subscene_name si existe
	if subscene_name != "":
		current_scene_name = subscene_name

	# Solo si cambió de escena
	if current_scene_name != last_scene_name:
		last_scene_name = current_scene_name
		update_music(current_scene_name)

	# Si estás cerca del jefe, cambia la música dinámicamente
	if is_near_boss:
		if !musicboss.playing:
			stop_all_music()
			musicboss.play()
	else:
		# Si ya no está cerca del boss y boss music está sonando, volver a música normal
		if musicboss.playing:
			update_music(current_scene_name)

func stop_all_music():
	musicboss.stop()
	musiclevel.stop()
	musicmainmenu.stop()

func update_music(current_scene_name: String):
	stop_all_music()
	
	if current_scene_name.begins_with("level_"):
		musiclevel.play()
	elif current_scene_name == "Chose_Character" or current_scene_name == "Main Menu":
		musicmainmenu.play()
