extends CanvasLayer

@onready var mainmenu = $"main menu"
@onready var optionsmenu = $Options
@onready var onlinemenu = $Multiplayer
@onready var serverbrowsermenu = $MultiplayerList
@onready var Version = $Version

func _ready() -> void:
	GameController.main_menu = self
	optionsmenu.visible = false
	mainmenu.visible = true
	onlinemenu.visible = false
	serverbrowsermenu.visible = false

	Version.text = "V" + str(GameController.version)
	
	LoadGameData()

func LoadGameData():
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
	var config = ConfigFile.new()
	config.load("user://config.cfg")
	config.save("user://config.cfg")

func _on_play_pressed() -> void:
	LoadScene.LoadCharacterMenu(self)

func _on_online_pressed() -> void:
	mainmenu.visible = !mainmenu.visible
	onlinemenu.visible = !onlinemenu.visible


func _on_option_pressed() -> void:
	optionsmenu.visible = !optionsmenu.visible
	mainmenu.visible = !mainmenu.visible


func _on_delete_data_pressed() -> void:
	GameData.DeleteData()
	get_tree().quit()
	


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	optionsmenu.visible = !optionsmenu.visible
	mainmenu.visible = !mainmenu.visible


func _on_check_button_toggled(toggled_on: bool) -> void:
	var config = ConfigFile.new()
	config.load("user://config.cfg")
	
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	config.set_value("config", "fullscreen", toggled_on)
	config.save("user://config.cfg")


func _on_h_slider_value_changed(value: float) -> void:
	var config = ConfigFile.new()
	config.load("user://config.cfg")
	
	var volume_index = 2 # SFX
	AudioServer.set_bus_volume_db(volume_index, linear_to_db(value))
	config.set_value("config", "sfx volume", value)
	config.save("user://config.cfg")


func _on_volume_2_value_changed(value: float) -> void:
	var config = ConfigFile.new()
	config.load("user://config.cfg")
	
	var volume_index = 1
	AudioServer.set_bus_volume_db( volume_index, linear_to_db(value))
	config.set_value("config", "music volume", value)
	config.save("user://config.cfg")


func _on_ip_text_changed(new_text: String) -> void:
	Network.ip = new_text
	
func _on_port_text_changed(new_text: String) -> void:
	Network.port = new_text.to_int()
	Network.listener_port = Network.port - 1
	Network.broadcaster_port = Network.port + 1
	Network.SetUp()

func _on_play_multiplayer_pressed() -> void:
	Network.Play_MultiplayerServer()

func _on_play_multiplayer_client_pressed() -> void:
	Network.Play_MultiplayerClient()


func _on_back_2_pressed() -> void:
	mainmenu.visible = !mainmenu.visible
	onlinemenu.visible = !onlinemenu.visible


func _on_name_text_changed(new_text:String) -> void:
	Network.Username = new_text

func _on_online_list_pressed() -> void:
	onlinemenu.visible = !onlinemenu.visible
	serverbrowsermenu.visible = !serverbrowsermenu.visible


func _on_back_3_pressed() -> void:
	onlinemenu.visible = !onlinemenu.visible
	serverbrowsermenu.visible = !serverbrowsermenu.visible
