extends RigidBody2D

@export var coin_id: String
@export var collected = false

@onready var coinsound = $"coin sound"
var path = "user://data.cfg"

func _ready() -> void:
	LoadGameData()
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
		
	if GameController.IsNetwork:
		hide_coin.rpc()
	else:
		hide_coin()
		
		
func SaveGameData():
	if GameController.IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return

			
	var config = ConfigFile.new()
	
	if config.get_value("data3", coin_id, false) == true:
		return
		
	config.load(path)
	config.set_value("data3", coin_id, collected)
	config.save(path)

func LoadGameData():
	if GameController.IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return
	
	var config = ConfigFile.new()
	if config.load(path) == OK:
		if config.has_section_key("data2", name + "_ID"):
			coin_id = config.get_value("data2", name + "_ID")
		else:
			coin_id = str(randi())
			config.set_value("data2",  name + "_ID", coin_id)
			config.save(path)
			
	
		if config.get_value("data3", coin_id, false) == true:
			if GameController.IsNetwork:
				hide_coin.rpc()
			else:
				hide_coin()
	

@rpc("any_peer", "call_local")
func hide_coin():
	if visible:
		coinsound.play()
		GameController.getcoin()
		visible = !visible
		collected = !collected
		SaveGameData()
		await coinsound.finished
		queue_free()
