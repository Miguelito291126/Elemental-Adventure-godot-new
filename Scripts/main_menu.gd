extends Control

@onready var mainmenu = $"Panel/main menu"
@onready var optionsmenu = $Panel/Options
@onready var volume = $Panel/Options/Volume
@onready var volume2 = $"Panel/Options/Volume 2"
@onready var fullscreen = $Panel/Options/CheckButton
@onready var serverbrowsermenu = $Panel/Multiplayer
@onready var username_line = $Panel/Multiplayer/Name
@onready var port_line = $Panel/Multiplayer/Port
@onready var version = $Panel/Version
@onready var credits = $Panel/Credits
@onready var tittle = $"Panel/main menu/Title/Tittle"
@onready var private_mode = $Panel/Multiplayer/PrivateMode

func _ready() -> void:
	GameController.main_menu = self
	optionsmenu.visible = false
	mainmenu.visible = true
	serverbrowsermenu.visible = false

	LoadGameData()

	username_line = Network.Username
	port_line.text = str(Network.port)
	private_mode.button_pressed = Network.private_mode

	version.text = "V" + GameController.version
	credits.text = "By " + GameController.credits
	tittle.text = GameController.gamename

	if OS.has_feature("dedicated_server") or "s" in OS.get_cmdline_user_args() or "server" in OS.get_cmdline_user_args():

		var args = OS.get_cmdline_user_args()

		for i in range(args.size()):
			Network.print_role("args: " + args[i])
			match args[i]:
				"--port", "port", "-p", "p":
					if i + 1 < args.size():
						Network.port = args[i + 1].to_int()


		Network.print_role("port:" + str(Network.port))
		Network.print_role("ip:" + IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4))

		Network.print_role("Iniciando servidor dedicado...")

		await get_tree().create_timer(2).timeout

		Network.create_steam_lobby()


func LoadGameData():
	self.volume.value = GameController.GameData.sfx
	self.volume2.value = GameController.GameData.music
	self.fullscreen.button_pressed = GameController.GameData.fullscreen

	AudioServer.set_bus_volume_db(1, linear_to_db(GameController.GameData.music))
	AudioServer.set_bus_volume_db(2, linear_to_db(GameController.GameData.sfx))
	if GameController.GameData.fullscreen == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		




func _on_play_pressed() -> void:
	LoadScene.LoadCharacterMenu(self)

func _on_online_pressed() -> void:
	mainmenu.visible = !mainmenu.visible
	serverbrowsermenu.visible = !serverbrowsermenu.visible


func _on_option_pressed() -> void:
	optionsmenu.visible = !optionsmenu.visible
	mainmenu.visible = !mainmenu.visible


func _on_delete_data_pressed() -> void:
	GameController.GameData.DeleteData()
	GamePersistentData.DeletePersistentNodes()
	
	


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	optionsmenu.visible = !optionsmenu.visible
	mainmenu.visible = !mainmenu.visible


func _on_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	GameController.GameData.fullscreen = toggled_on
	GameController.GameData.SaveGameData()


func _on_h_slider_value_changed(value: float) -> void:
	var volume_index = 2 # SFX
	AudioServer.set_bus_volume_db(volume_index, linear_to_db(value))
	GameController.GameData.sfx = value
	GameController.GameData.SaveGameData()


func _on_volume_2_value_changed(value: float) -> void:
	var volume_index = 1
	AudioServer.set_bus_volume_db( volume_index, linear_to_db(value))
	GameController.GameData.music = value
	GameController.GameData.SaveGameData()


func _on_ip_text_changed(new_text: String) -> void:
	Network.ip = new_text
	
func _on_port_text_changed(new_text: String) -> void:
	Network.port = new_text.to_int()

func _on_play_multiplayer_pressed() -> void:
	Network.create_steam_lobby()

func _on_play_multiplayer_client_pressed() -> void:
	Network.Play_MultiplayerClient()


func _on_back_2_pressed() -> void:
	mainmenu.visible = !mainmenu.visible
	serverbrowsermenu.visible = !serverbrowsermenu.visible


func _on_name_text_changed(new_text:String) -> void:
	Network.Username = new_text

func _on_online_list_pressed() -> void:
	serverbrowsermenu.visible = !serverbrowsermenu .visible


func _on_back_3_pressed() -> void:
	mainmenu.visible = !mainmenu.visible
	serverbrowsermenu.visible = !serverbrowsermenu.visible


func _on_private_mode_toggled(toggled_on: bool) -> void:
	Network.private_mode = toggled_on
