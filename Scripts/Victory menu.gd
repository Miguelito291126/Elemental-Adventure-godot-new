extends Control

@onready var energys = $Panel/VBoxContainer2/energys
@onready var score = $Panel/VBoxContainer2/score
@onready var level = $Panel/VBoxContainer2/level
@onready var next_button = $Panel/VBoxContainer/next

func _ready() -> void:
	GameController.victory_menu = self

	if OS.has_feature("dedicated_server"):
		await get_tree().create_timer(5).timeout
		load_level_scene.rpc()

	# Deshabilitar el botón Play para clientes
	if not multiplayer.is_server():
		next_button.disabled = true
		next_button.text = "Wait..."

	level.text = str("You completed level: ",  GameController.level - 1)
	score.text = str("Score: ",  GameController.points)
	energys.text = str("Energys: ", GameController.energys) # ← Cambiado a energys real

func _on_back_pressed() -> void:
	Network.close_conection()
	queue_free()


@rpc("any_peer", "call_local")
func load_level_scene():
	LoadScene.load_level_scene(self)

func _on_next_pressed() -> void:
	# Solo el servidor puede presionar Play
	if not multiplayer.is_server():
		return

	load_level_scene.rpc()

