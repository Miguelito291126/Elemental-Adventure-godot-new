extends RigidBody2D

@export var hearth_id: String
@export var collected = false

@onready var hearthsound = $"hearth sound"

var path = "user://data.cfg"

func _ready() -> void:		
	LoadGameData()


func SaveGameData():
	if GameController.IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return
			
	var config = ConfigFile.new()
	config.load(path)
	config.set_value("data3", hearth_id, collected)
	config.save(path)

func LoadGameData():
	
	if GameController.IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return

	var config = ConfigFile.new()
	if config.load(path) == OK:
		if config.has_section_key("data2", name + "_ID"):
			hearth_id = config.get_value("data2", name + "_ID")
		else:
			hearth_id = str(randi())
			config.set_value("data2",  name + "_ID", hearth_id)
			config.save(path)
			
		if config.get_value("data3", hearth_id, false) == true:
			if GameController.IsNetwork:
				hide_hearth.rpc(null)
			else:
				hide_hearth(null)
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return

	if GameController.IsNetwork:
		hide_hearth.rpc(body)
	else:
		hide_hearth(body)
		


	
@rpc("any_peer", "call_local")
func hide_hearth(body):
	if visible:
		body.healting(1)
		hearthsound.play()
		visible = !visible
		collected = !collected
		SaveGameData()
		await hearthsound.finished
		queue_free()
