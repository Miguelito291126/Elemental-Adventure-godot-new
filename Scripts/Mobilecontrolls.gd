extends CanvasLayer

func _enter_tree() -> void:
	if GameController.IsNetwork:
		set_multiplayer_authority(get_parent().name.to_int())
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !is_multiplayer_authority() and GameController.IsNetwork:
		return
	
	match OS.get_name():
		"Android", "iOS":
			show()
		_:
			hide()
		
