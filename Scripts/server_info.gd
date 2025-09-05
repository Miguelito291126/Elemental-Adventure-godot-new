extends HBoxContainer

func _on_join_pressed() -> void:
    GameController.ip = $IP.text
    GameController.port = int($Port.text)
    GameController.Play_MultiplayerClient()
