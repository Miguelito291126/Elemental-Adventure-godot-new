extends Control

@onready var mainmenu = $"Panel/main menu"
@onready var optionsmenu = $Panel/Options
@onready var volume = $Panel/Options/Volume
@onready var volume2 = $"Panel/Options/Volume 2"
@onready var fullscreen = $Panel/Options/CheckButton
@onready var onlinemenu = $Panel/Multiplayer
@onready var serverbrowsermenu = $Panel/MultiplayerList
@onready var username_line = $Panel/Multiplayer/Name
@onready var ip_line = $Panel/Multiplayer/IP
@onready var port_line = $Panel/Multiplayer/Port
@onready var version = $Panel/Version
@onready var credits = $Panel/Credits
@onready var tittle = $"Panel/main menu/Title/Tittle"

func _ready() -> void:
	GameController.main_menu = self
	optionsmenu.visible = false
	mainmenu.visible = true
	onlinemenu.visible = false
	serverbrowsermenu.visible = false

	LoadGameData()

	username_line = Network.Username
	ip_line.text = Network.ip
	port_line.text = str(Network.port)

	version.text = "V" + GameController.version
	credits.text = "By " + GameController.credits
	tittle.text = GameController.gamename

	Network.SetUpLisener()

	if OS.has_feature("dedicated_server") or "s" in OS.get_cmdline_user_args() or "server" in OS.get_cmdline_user_args():

		var args = OS.get_cmdline_user_args()

		for i in range(args.size()):
			Network.print_role("args: " + args[i])
			match args[i]:
				"--port", "port", "-p", "p":
					if i + 1 < args.size():
						Network.port = args[i + 1].to_int()
						Network.listener_port = Network.port + 1
						Network.broadcaster_port = Network.port - 1


		Network.print_role("port:" + str(Network.port))
		Network.print_role("ip:" + IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4))

		Network.print_role("Iniciando servidor dedicado...")

		await get_tree().create_timer(2).timeout

		Network.Play_MultiplayerServer()


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
			
		self.volume.value = sfx
		self.volume2.value = music
		self.fullscreen.button_pressed = fullscreen
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
	Network.listener_port = Network.port + 1
	Network.broadcaster_port = Network.port - 1
	Network.SetUpLisener()

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
