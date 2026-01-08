extends CanvasLayer

@onready var pause_menu = $"Panel/Pause menu"
@onready var optionsmenu = $Panel/Options
@onready var volume = $Panel/Options/Volume
@onready var volume2 = $"Panel/Options/Volume 2"
@onready var fullscreen = $Panel/Options/CheckButton


func _enter_tree() -> void:
	set_multiplayer_authority(get_parent().name.to_int())

func _ready() -> void:
	GameController.pause_menu = self

	pause_menu.visible = true
	optionsmenu.visible = false

	LoadGameData()


func LoadGameData():
	if !is_multiplayer_authority():
		return
		
	self.volume.value = GameController.GameData.sfx
	self.volume2.value = GameController.GameData.music
	self.fullscreen.button_pressed = GameController.GameData.fullscreen

	AudioServer.set_bus_volume_db(1, linear_to_db(GameController.GameData.music))
	AudioServer.set_bus_volume_db(2, linear_to_db(GameController.GameData.sfx))
	if GameController.GameData.fullscreen == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

		
func SaveGameData():
	if !is_multiplayer_authority():
		return
		
	GameController.GameData.SaveGameData()
	
func _on_save_pressed() -> void:
	if !is_multiplayer_authority():
		return
		

	SaveGameData()


func _on_reset_player_pressed() -> void:
	if !is_multiplayer_authority():
		return

	get_parent().RespawnPos()
	

func _on_return_pressed() -> void:
	if !is_multiplayer_authority():
		return
		
	pause()

func _on_back_pressed() -> void:
	pause()

	if !is_multiplayer_authority():
		return

	Network.close_conection()


func pause():
	if !is_multiplayer_authority():
		return
			
	visible = !visible
	
	if multiplayer.multiplayer_peer == null \
	or multiplayer.multiplayer_peer is OfflineMultiplayerPeer \
	or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		get_tree().paused = visible

func _on_back_pause_menu_pressed() -> void:
	if !is_multiplayer_authority():
		return

	optionsmenu.visible = !optionsmenu.visible
	pause_menu.visible = !pause_menu.visible



func _on_settings_pressed() -> void:
	if !is_multiplayer_authority():
		return
			
	optionsmenu.visible = !optionsmenu.visible
	pause_menu.visible = !pause_menu.visible


func _on_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	GameController.GameData.fullscreen = toggled_on
	GameController.GameData.SaveGameData()


func _on_volume_value_changed(value: float) -> void:
	var volume_index = 2 # SFX
	AudioServer.set_bus_volume_db(volume_index, linear_to_db(value))
	GameController.GameData.sfx = value
	GameController.GameData.SaveGameData()


func _on_volume_2_value_changed(value: float) -> void:
	var volume_index = 1
	AudioServer.set_bus_volume_db( volume_index, linear_to_db(value))
	GameController.GameData.music = value
	GameController.GameData.SaveGameData()
