extends CanvasLayer

@onready var fire_button = $Panel/fire/Button_fire
@onready var water_button = $Panel/water/Button_water
@onready var air_button = $Panel/air/Button_air
@onready var earth_button = $Panel/earth/Button_earth

func _ready():
	if Network.IsNetwork:
		fire_button.disabled = true
		water_button.disabled = true
		air_button.disabled = true
		earth_button.disabled = true


func _on_button_fire_pressed() -> void:
	Network.character = "fire"


func _on_button_water_pressed() -> void:
	Network.character = "water"


func _on_button_air_pressed() -> void:
	Network.character = "air"

func _on_button_earth_pressed() -> void:
	Network.character = "earth"


func _on_play_pressed() -> void:
	if Network.IsNetwork:
		if multiplayer.is_server():  # Solo el MasterClient puede hacer esto
			LoadScene.load_level_scene(self)
	else:
		LoadScene.load_level_scene(self)


func _on_exit_pressed() -> void:
	if Network.IsNetwork:
		Network.multiplayerpeer.close()
	else:
		LoadScene.LoadMainMenu(self)
