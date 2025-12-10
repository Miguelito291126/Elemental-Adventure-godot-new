extends Control

@onready var Text = $CenterContainer/Logo

@export var scene: PackedScene

@export var in_time: float = 0.5
@export var out_time: float = 0.5
@export var fade_in_time: float = 1.5
@export var fade_out_time: float = 1.5
@export var pause_time: float = 1.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_fade()


func _fade():
	Text.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_interval(in_time)
	tween.tween_property(Text, "modulate:a",  1.0, fade_in_time)
	tween.tween_interval(pause_time)
	tween.tween_property(Text, "modulate:a",  0.0, fade_out_time)
	tween.tween_interval(out_time)

	await tween.finished

	get_tree().change_scene_to_packed(scene)
