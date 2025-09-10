extends CanvasLayer

signal safe_to_load

@onready var progress_bar = $Control/ProgressBar
@onready var animationplayer = $AnimationPlayer

func update_progress_bar(new_value: float):
	progress_bar.value = new_value

func fade_out_loading_screen():
	animationplayer.play("fade_out")
	await animationplayer.animation_finished
	self.queue_free()
