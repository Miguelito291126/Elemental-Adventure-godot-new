extends Control

@onready var label = $"../Label"
var currentinfo: PackedScene = preload("res://Scenes/server_info.tscn")

func _ready():
	GameController.serverbrowser = self

func _process(_delta):
	if GameController.listener.get_available_packet_count() > 0:
		var serverip = GameController.listener.get_packet_ip()
		var serverport = GameController.listener.get_packet_port()
		var bytes = GameController.listener.get_packet()
		var data = bytes.get_string_from_ascii()
		var roominfo = JSON.parse_string(data)

		print("Server Info: " + data)
		
		for i in $List.get_children():
			if i.name == roominfo.name:
				i.get_node("Name").text = roominfo.name + " / "
				i.get_node("PlayerCount").text = str(roominfo.playerscount) + " /"
				i.ip_Change = serverip
				i.port_Change = str(serverport)
				return

		var currentinfo2 = currentinfo.instantiate()
		currentinfo2.name = roominfo.name
		currentinfo2.get_node("Name").text = roominfo.name + " / "
		currentinfo2.get_node("PlayerCount").text = str(roominfo.playerscount) + " / "
		currentinfo2.ip_Change = serverip
		currentinfo2.port_Change = str(serverport)
		$List.add_child(currentinfo2)
