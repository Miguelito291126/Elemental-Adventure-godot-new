extends DirectionalLight2D

var base_angle = 0

@export var gradient: GradientTexture1D

func _ready():
	self.rotation_degrees = 0

func _process(_delta):
	var value = (sin(Globals.time - PI / 2.0) + 1.0) / 2.0
	self.color = gradient.gradient.sample(value)
	self.enabled = Globals.Graphics
	self.shadow_enabled = Globals.Graphics
	self.shadow_filter_smooth = 4 - Globals.Graphics
	if Globals.Graphics == 0:
		self.shadow_filter = SHADOW_FILTER_NONE
	elif Globals.Graphics == 2:
		self.shadow_filter = SHADOW_FILTER_PCF5
	elif Globals.Graphics == 3:
		self.shadow_filter = SHADOW_FILTER_PCF13
	else:
		if Globals.Graphics > 3 :
			self.shadow_filter = SHADOW_FILTER_PCF13
		elif Globals.Graphics < 0:
			self.shadow_filter = SHADOW_FILTER_NONE
		else:
			self.shadow_filter = SHADOW_FILTER_PCF5

	self.rotation_degrees = lerpf(self.rotation_degrees, 180 - float((Globals.minute + Globals.hour * 60) * 0.2500005), Globals.time_speed * _delta)

