extends TileMapLayer

@onready var destrolledeearth = $Background
@onready var lava = $Background2
@onready var desert = $Background3

func _process(delta: float) -> void:
	if GameController.level >= 1 and  GameController.level <= 6:
		lava.visible = false
		desert.visible = false
		destrolledeearth.visible = true
	elif GameController.level > 6 and  GameController.level <= 12:
		lava.visible =  true
		desert.visible = false
		destrolledeearth.visible = false
		
	elif GameController.level > 12 and  GameController.level <= 18:
		lava.visible = false
		desert.visible = true
		destrolledeearth.visible = false
	else: 
		lava.visible = false
		desert.visible = false
		destrolledeearth.visible = false
