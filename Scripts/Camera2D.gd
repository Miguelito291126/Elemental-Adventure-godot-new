extends Camera2D

func _process(_delta):
	if Network.is_networking:
		$environment.visible = true
	else: 
		$environment.visible = false
