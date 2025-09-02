extends Control

func _ready() -> void:
    if OS.get_name() == "Android" or OS.get_name() == "IOS":
        # Si estamos en Android, habilitar el botón de salto
       visible = true
    else:
        # En otras plataformas, deshabilitar el botón de salto
       visible = false