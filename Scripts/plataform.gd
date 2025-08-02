extends Path2D

@export var loop: bool = true
@export var speed: float = 2
@export var speed_scale: float = 1
@onready var pathfollow = $PathFollow2D
@onready var plataform = $PathFollow2D/RemoteTransform2D
@onready var animationplayer = $AnimationPlayer
@onready var animation = "move"

func _ready():
	if not loop:
		animationplayer.play(animation)
		animationplayer.speed_scale = speed_scale
		set_process(false)

func _process(_delta):
	pathfollow.progress += speed
