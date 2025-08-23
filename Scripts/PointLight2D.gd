extends PointLight2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
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
