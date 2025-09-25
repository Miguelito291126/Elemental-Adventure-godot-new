extends Control

@onready var label = $"../Label"
@onready var list = $List
const TIMEOUT = 3.0

var currentinfo: PackedScene = preload("res://Scenes/server_info.tscn")

func _ready():
	Network.serverbrowser = self

func _process(_delta):
	var now = Time.get_unix_time_from_system()
	Reload(now)

	if Network.listener.get_available_packet_count() > 0:
		var serverip = Network.listener.get_packet_ip()
		var serverport = Network.listener.get_packet_port()
		var bytes = Network.listener.get_packet()
		var data = bytes.get_string_from_ascii()
		var roominfo = JSON.parse_string(data)

		Network.print_role("Server Info: " + data)
		
		for i in list.get_children():
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
		list.add_child(currentinfo2)

		
func Reload(now): 
	for i in list.get_children(): 
		if i is HBoxContainer: 
			if now - i.last_seen > TIMEOUT: 
				print("Eliminando servidor inactivo:", i.name) 
				i.queue_free()