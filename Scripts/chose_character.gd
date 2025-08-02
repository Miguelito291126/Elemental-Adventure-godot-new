extends CanvasLayer

func _ready():
	if GameController.IsNetwork:
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
	if GameController.IsNetwork:
		if multiplayer.is_server():  # Solo el MasterClient puede hacer esto
			GameController.load_level_scene()
	else:
		GameController.load_level_scene()
