extends TileMapLayer

@onready var destrolledeearth = $Background
@onready var lava = $Background2
@onready var desert = $Background3
@onready var snow = $Background4
@onready var dark = $Background5

func _process(_delta: float) -> void:
	if GameController.level > 0 and  GameController.level <= 5:
		lava.visible = false
		desert.visible = false
		destrolledeearth.visible = true
		snow.visible = false
		dark.visible = false
	elif GameController.level > 5 and  GameController.level <= 10:
		lava.visible =  true
		desert.visible = false
		destrolledeearth.visible = false
		snow.visible = false
		dark.visible = false
	elif GameController.level > 10 and  GameController.level <= 15:
		lava.visible = false
		desert.visible = true
		destrolledeearth.visible = false
		snow.visible = false
		dark.visible = false
	elif GameController.level > 15 and  GameController.level <= 20:
		lava.visible = false
		desert.visible = false
		destrolledeearth.visible = false
		snow.visible = true
		dark.visible = false
	elif GameController.level > 20 and GameController.level <= 25:
		lava.visible = false
		desert.visible = false
		destrolledeearth.visible = false
		snow.visible = true
		dark.visible = true
	else: 
		lava.visible = false
		desert.visible = false
		destrolledeearth.visible = false
		snow.visible = false
		dark.visible = true
