extends Area2D

@export var speed = 600
@export var direction = Vector2.RIGHT

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(_body: Node2D) -> void:
	queue_free()


func _on_area_entered(area:Area2D) -> void:
	if area.is_in_group("bullet"):
		queue_free()
