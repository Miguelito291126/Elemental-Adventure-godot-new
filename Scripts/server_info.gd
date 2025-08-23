extends HBoxContainer

func _on_join_pressed():
	Signals.JoinGame.emit($ip.text, int($port.text))
