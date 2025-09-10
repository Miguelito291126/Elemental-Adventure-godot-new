extends CanvasLayer

func _ready():
	if Network.IsNetwork:
		$fire/Button_fire.disabled = true
		$water/Button_water.disabled = true
		$air/Button_air.disabled = true
		$earth/Button_earth.disabled = true


func _on_button_fire_pressed() -> void:
	GameController.character = "fire"


func _on_button_water_pressed() -> void:
	GameController.character = "water"


func _on_button_air_pressed() -> void:
	GameController.character = "air"

func _on_button_earth_pressed() -> void:
	GameController.character = "earth"


func _on_play_pressed() -> void:
	if Network.IsNetwork:
		if multiplayer.is_server():  # Solo el MasterClient puede hacer esto
			LoadScene.load_level_scene(self)
	else:
		LoadScene.load_level_scene(self)
