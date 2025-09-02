extends CanvasLayer

@onready var main_menu = $"Pause menu"
@onready var pause_menu = $Options

func _enter_tree() -> void:
	if GameController.IsNetwork:
		set_multiplayer_authority(get_parent().name.to_int())
	
func _ready() -> void:
	LoadGameData()
		
func LoadGameData():
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
			
	var config = ConfigFile.new()
	var err = config.load("user://config.cfg")
	
	if err == OK:
		var music = config.get_value("config", "music volume", 1.0)
		var sfx = config.get_value("config", "sfx volume", 1.0)
		var fullscreen = config.get_value("config", "fullscreen", true)

		AudioServer.set_bus_volume_db(1, linear_to_db(music))
		AudioServer.set_bus_volume_db(2, linear_to_db(sfx))
		if fullscreen == true:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			
		$Options/Volume.value = sfx
		$"Options/Volume 2".value = music
		$Options/CheckButton.button_pressed = fullscreen
	else:
		prints("No se pudo acceder a la carpeta")
		
func SaveGameData():
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
			
	var config = ConfigFile.new()
	config.load("user://config.cfg")
	config.save("user://config.cfg")
	
	GameController.SaveGameData()
	GameController.SavePersistentNodes()
	
func _on_save_pressed() -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
		

	SaveGameData()


func _on_reset_player_pressed() -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return

	get_parent().RespawnPos()
	

func _on_return_pressed() -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
		
	visible = !visible

func _on_back_pressed() -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
		GameController.multiplayerpeer.close()
	else:
		GameController.DeletePersistentNodes()
		GameController.LoadMainMenu()



func _on_back_pause_menu_pressed() -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return

	pause_menu.visible = !pause_menu.visible
	main_menu.visible = !main_menu.visible


func _on_settings_pressed() -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
			
	
	pause_menu.visible = !pause_menu.visible
	main_menu.visible = !main_menu.visible


func _on_check_button_toggled(toggled_on: bool) -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
	
	var config = ConfigFile.new()
	config.load("user://config.cfg")
	
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	config.set_value("config", "fullscreen", toggled_on)
	config.save("user://config.cfg")


func _on_volume_value_changed(value: float) -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
	
	var config = ConfigFile.new()
	config.load("user://config.cfg")
	
	var volume_index = 2 # SFX
	AudioServer.set_bus_volume_db(volume_index, linear_to_db(value))
	config.set_value("config", "sfx volume", value)
	config.save("user://config.cfg")


func _on_volume_2_value_changed(value: float) -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
	
	var config = ConfigFile.new()
	config.load("user://config.cfg")
	
	var volume_index = 1
	AudioServer.set_bus_volume_db( volume_index, linear_to_db(value))
	config.set_value("config", "music volume", value)
	config.save("user://config.cfg")
