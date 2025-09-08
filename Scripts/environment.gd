extends TileMapLayer

@onready var destrolledeearth = $Background
@onready var lava = $Background2
@onready var desert = $Background3
@onready var snow = $Background4

func _process(_delta: float) -> void:
	if GameController.level > 0 and  GameController.level <= 6:
		lava.visible = false
		desert.visible = false
		destrolledeearth.visible = true
		snow.visible = false
	elif GameController.level > 6 and  GameController.level <= 12:
		lava.visible =  true
		desert.visible = false
		destrolledeearth.visible = false
		snow.visible = false
	elif GameController.level > 12 and  GameController.level <= 18:
		lava.visible = false
		desert.visible = true
		destrolledeearth.visible = false
		snow.visible = false
	elif GameController.level > 18 and  GameController.level <= 24:
		lava.visible = false
		desert.visible = false
		destrolledeearth.visible = false
		snow.visible = true
	else: 
		lava.visible = false
		desert.visible = false
		destrolledeearth.visible = false
		snow.visible = false
