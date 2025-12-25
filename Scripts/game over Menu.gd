extends Control

@onready var energys = $Panel/VBoxContainer2/energys
@onready var score = $Panel/VBoxContainer2/score
@onready var return_button = $Panel/VBoxContainer/return

func _ready() -> void:
	GameController.game_over_menu = self

	# Deshabilitar el botón Play para clientes
	if not multiplayer.is_server():
		return_button.disabled = true
		return_button.text = "Wait..."

	score.text = str("Score: ",  GameController.points)
	energys.text = str("Energys: ", GameController.energys) # ← Cambiado a energys real

# Botón volver al menú
func _on_back_pressed() -> void:		
	Network.close_conection()
	queue_free()


@rpc("any_peer", "call_local")
func load_level_scene():
	LoadScene.load_level_scene(self)

# Botón volver al nivel actual
func _on_return_pressed() -> void:
	# Solo el servidor puede presionar Play
	if not multiplayer.is_server():
		return

	load_level_scene.rpc()

