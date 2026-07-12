extends Control

func _ready() -> void:
    if OS.get_name() == "Android" or OS.get_name() == "IOS":
        visible = true
    else:
        visible = false