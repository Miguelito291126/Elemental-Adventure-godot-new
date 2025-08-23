extends CanvasLayer

@onready var level = get_parent()
@onready var player = get_parent().get_node(str(multiplayer.get_unique_id()))

func _on_button_fire_pressed() -> void:
	Globals.player_index = 0
	
	if Network.is_host:
		Network.hostbyport(Network.port)
	else:
		Network.joinbyip(Network.ip, Network.port)



func _on_button_water_pressed() -> void:
	Globals.player_index = 1
	
	if Network.is_host:
		Network.hostbyport(Network.port)
	else:
		Network.joinbyip(Network.ip, Network.port)


func _on_button_air_pressed() -> void:
	Globals.player_index = 2

	if Network.is_host:
		Network.hostbyport(Network.port)
	else:
		Network.joinbyip(Network.ip, Network.port)

func _on_button_earth_pressed() -> void:
	Globals.player_index = 3
	
	if Network.is_host:
		Network.hostbyport(Network.port)
	else:
		Network.joinbyip(Network.ip, Network.port)
