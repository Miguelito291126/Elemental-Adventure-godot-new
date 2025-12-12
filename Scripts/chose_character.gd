extends CanvasLayer

@onready var fire_button = $Panel/fire/Button_fire
@onready var water_button = $Panel/water/Button_water
@onready var air_button = $Panel/air/Button_air
@onready var earth_button = $Panel/earth/Button_earth
@onready var play_button = $Panel/VBoxContainer/Play

func _ready():
	GameController.chose_characters = self
	update_character_buttons()
	
	# Deshabilitar el botón Play para clientes
	if not multiplayer.is_server():
		play_button.disabled = true
		play_button.text = "Wait..."
	
	# Si el servidor ya está en el nivel, deshabilitar el botón Play
	if GameController.levelnode and is_instance_valid(GameController.levelnode):
		play_button.disabled = true
		play_button.text = "Game Started"
	
	# Si somos cliente, solicitar sincronización inicial al servidor
	if not multiplayer.is_server() and multiplayer.multiplayer_peer != null:
		# Esperar un frame para asegurar que la conexión esté lista
		await get_tree().process_frame
		request_sync_assigned_characters()

func request_sync_assigned_characters():
	# Solicitar sincronización al servidor
	if multiplayer.is_server():
		# Si somos servidor, llamar directamente
		Network.request_sync_assigned_characters()
	else:
		# Si somos cliente, enviar RPC al servidor
		Network.request_sync_assigned_characters.rpc()

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
	# Solo el servidor puede presionar Play
	if not multiplayer.is_server():
		return
		
	# Si el servidor ya está en el nivel, no hacer nada
	if GameController.levelnode and is_instance_valid(GameController.levelnode):
		return
		
	# El servidor carga el nivel y notifica a los clientes
	Network.hide_character_selection_menu.rpc()
	Network.hide_character_selection_menu()  # Ocultar localmente también
	LoadScene.load_level_scene(self)

func _on_exit_pressed() -> void:
	# Si el servidor ya está en el nivel, solo cerrar la pantalla sin desconectar
	if not multiplayer.is_server() and GameController.levelnode and is_instance_valid(GameController.levelnode):
		# El servidor ya está en el nivel, solo ocultar la pantalla
		queue_free()
		GameController.chose_characters = null
	else:
		# Si no está en el nivel, cerrar la conexión
		Network.close_conection()