class_name DataResource extends Resource

static var path = "user://data.tres"

#Globals Settings
@export var sfx = 0.5
@export var music = 0.5
@export var fullscreen = false
@export var energys = 0
@export var points = 0
@export var level = 1

func SaveGameData():

	level = GameController.level
	points = GameController.points
	energys = GameController.energys

	ResourceSaver.save(self, path)

static func LoadGameData():
	var data: DataResource = load(path) as DataResource
	if not data:
		data = DataResource.new()

	return data


func DeleteResource():
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		
func DeleteData():
	GamePersistentData.DeletePersistentNodes()
	DeleteResource()
