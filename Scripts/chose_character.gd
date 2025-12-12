extends CanvasLayer

@onready var fire_button = $Panel/fire/Button_fire
@onready var water_button = $Panel/water/Button_water
@onready var air_button = $Panel/air/Button_air
@onready var earth_button = $Panel/earth/Button_earth

func _ready():
	GameController.chose_characters = self
	update_character_buttons()

func update_character_buttons():
	var used_characters = []
	for character in Network.assigned_characters.values():
		used_characters.append(character)

	fire_button.disabled = "fire" in used_characters
	water_button.disabled = "water" in used_characters
	air_button.disabled = "air" in used_characters
	earth_button.disabled = "earth" in used_characters

func _on_button_fire_pressed() -> void:
	if not fire_button.disabled:
		request_character("fire")

func _on_button_water_pressed() -> void:
	if not water_button.disabled:
		request_character("water")

func _on_button_air_pressed() -> void:
	if not air_button.disabled:
		request_character("air")

func _on_button_earth_pressed() -> void:
	if not earth_button.disabled:
		request_character("earth")

func request_character(character: String):
	# Verificar que el personaje no esté ya asignado
	if character in Network.assigned_characters.values():
		return
	
	if multiplayer.is_server():
		# Si soy servidor, llamo directamente
		Network.request_character(character)
	else:
		# Si soy cliente, envío RPC al servidor
		Network.request_character.rpc(character)

	

func _on_play_pressed() -> void:
	if multiplayer.is_server():
		LoadScene.load_level_scene(self)
	else:
		if GameController.levelnode and GameController.levelnode != null:
			UnloadScene.unload_scene(self)

func _on_exit_pressed() -> void:
	Network.close_conection()