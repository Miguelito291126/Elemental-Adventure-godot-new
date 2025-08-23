extends CanvasLayer

var hearths_size = 1200
@onready var player = get_parent()

func _process(_delta):
	update_label()

func update_label():
	$Panel/Hearths.size.x = player.Hearths * hearths_size
	$Panel2/Label2.text = ":" + str(player.energys)
	$Panel3/Label3.text = str(Globals.hour)  + ":" + str(Globals.minute)
	$Panel4/Label4.text =   "Score:" + str(player.score)
	$Panel5/Label.text =   ":" + str(player.deaths)
	$FPS.text = "FPS:" + str(Engine.get_frames_per_second())  
	$FPS.visible = Globals.FPS

