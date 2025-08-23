extends CanvasModulate

var minutes_per_day = 1440
var minutes_per_hour = 60
var ingame_to_real_minute_duration = (2 * PI) / minutes_per_day

@export var gradient:GradientTexture1D
@export var ingame_speed = 1
@export var initial_hour = 12:
	set(h):
		Globals.initial_time = h
		Globals.time = ingame_to_real_minute_duration * Globals.initial_time * minutes_per_hour

var past_minute = -1.0


func _ready():
	if Network.is_networking:
		if multiplayer.is_server():
			Globals.time = ingame_to_real_minute_duration * Globals.initial_time * minutes_per_hour
			Data.load_file()
	else:
		Globals.time = ingame_to_real_minute_duration * Globals.initial_time * minutes_per_hour
		Data.load_file()		

func _process(delta):
	if Network.is_networking:
		if multiplayer.is_server():
			Globals.time += delta * ingame_to_real_minute_duration * Globals.time_speed  
			var value = (sin(Globals.time - PI / 2.0) + 1.0) / 2.0
			self.color = gradient.gradient.sample(value)
		
			_recalculate_time()
	else:
		Globals.time += delta * ingame_to_real_minute_duration * Globals.time_speed  
		var value = (sin(Globals.time - PI / 2.0) + 1.0) / 2.0
		self.color = gradient.gradient.sample(value)

		_recalculate_time()


func _recalculate_time():
	var total_minutes = int(Globals.time / ingame_to_real_minute_duration)
	Globals.day = int(total_minutes / minutes_per_day)

	var current_day_minutes = total_minutes % minutes_per_day
	Globals.hour = int(current_day_minutes / minutes_per_hour)
	Globals.minute = int(current_day_minutes % minutes_per_hour)

	if past_minute != Globals.minute:
		past_minute = Globals.minute
		Signals.time_tick.emit(Globals.day, Globals.hour, Globals.minute)