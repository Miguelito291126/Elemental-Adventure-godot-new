extends Control

var broadcasttime: Timer
var currentinfo: PackedScene = preload("res://Scenes/server_info.tscn")

func _ready():
    GameController.serverbrowser = self
    broadcasttime = $Timer


func _process(_delta):
    if GameController.listener.get_available_packet_count() > 0:
        var serverip = GameController.listener.get_packet_ip()
        var serverport = GameController.listener.get_packet_port()
        var bytes = GameController.listener.get_packet()
        var data = bytes.get_string_from_ascii()
        var roominfo2 = JSON.parse_string(data)
		
        var child = $List.find_child(roominfo2.name)
        if child != null:
            child.get_node("PlayerCount").text = str(data.playersCount)
        else:
            var currentinfo2 = currentinfo.instantiate()
            currentinfo2.name = roominfo2.name
            currentinfo2.get_node("Name").text = roominfo2.name
            currentinfo2.get_node("IP").text = serverip
            currentinfo2.get_node("Port").text = str(serverport)
            currentinfo2.get_node("PlayerCount").text = str(roominfo2.playersCount)


func _on_timer_timeout() -> void:
    GameController.roominfo.playersCount = GameController.Players.size()
    var data = JSON.stringify(GameController.roominfo)
    var packet = data.to_ascii_buffer()
    if GameController.broadcaster != null:
        GameController.broadcaster.put_packet(packet)
        

func _exit_tree() -> void:
    GameController.listener.close()
    broadcasttime.stop()

    if GameController.broadcaster != null:
        GameController.broadcaster.close()