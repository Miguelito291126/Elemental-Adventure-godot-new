extends CharacterBody2D

@export var health := 10
@export var damagecount := 3
@export var color: Color
@export var enemy_id: String
@export var death := false

@onready var bulletscene = preload("res://Scenes/bullet.tscn")
@onready var bulletspawn = $bulletpos/bulletspawn
@onready var bulletpos = $bulletpos
@onready var shoot_timer = $Timer
@onready var animator = $AnimatedSprite2D

var is_invincible: bool = false
var invincibility_time := 1.5

const PATH := "user://data.cfg"
const DATA_SECTION := "data"
const ID_SECTION := "ID"

func _ready() -> void:
	# Animación inicial según color
	if color == Color.RED and !animator.is_playing():
		animator.play("robot Idle")
	elif color == Color.BLUE and !animator.is_playing():
		animator.play("robot 3 Idle")

	$PointLight2D.color = color


@rpc("any_peer", "call_local")
func damage(damage: int):
	if is_invincible:
		return

	health -= damage

	if GameController.IsNetwork:
		if health <= 0:
			kill.rpc()
		else:
			start_invincibility.rpc()
	else:
		if health <= 0:
			kill()
		else:
			start_invincibility()


@rpc("any_peer", "call_local")
func start_invincibility():
	is_invincible = true
	var blink_time := 0.1
	var total_time := 0.0
	var original_modulate := Color.WHITE

	while total_time < invincibility_time:
		modulate = Color.RED
		await get_tree().create_timer(blink_time).timeout
		modulate = Color.WHITE
		await get_tree().create_timer(blink_time).timeout
		total_time += blink_time * 2

	modulate = original_modulate
	is_invincible = false


@rpc("any_peer", "call_local")
func kill():
	if death:
		return
	death = true
	GameController.SavePersistentNodes()
	GameController.SaveGameData()
	queue_free()


func SaveGameData():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"death" : death,
		"health" : health
	}
	return save_dict

@rpc("any_peer", "call_local")
func remove_enemy():
	queue_free()


func _process(delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player_pos = players[0].global_position
		bulletpos.look_at(player_pos)

		# Voltear sprite según la posición del jugador
		animator.flip_h = player_pos.x >= global_position.x


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
		shoot_timer.start()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		shoot_timer.stop()


func _on_shoot_timer_timeout() -> void:
	if GameController.IsNetwork and !get_tree().get_multiplayer().is_server():
		return

	var players = get_tree().get_nodes_in_group("player")
	var closest_player = null
	var closest_distance = INF

	for p in players:
		var distance = global_position.distance_to(p.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_player = p

	if closest_player:
		var player_pos = closest_player.global_position
		var direction_to_player = (player_pos - global_position).normalized()
		bulletpos.look_at(player_pos)
		if GameController.IsNetwork:
			shoot.rpc(direction_to_player)
		else:
			shoot(direction_to_player)


@rpc("any_peer", "call_local")
func shoot(direction: Vector2):
	var bullet = bulletscene.instantiate()
	bullet.global_position = bulletspawn.global_position
	bullet.direction = direction
	bullet.modulate = color
	bullet.get_node("PointLight2D").color = color
	get_parent().add_child(bullet, true)


func _on_area_2d_2_area_entered(area: Area2D) -> void:
	if !area.is_in_group("bullet"):
		return

	if GameController.IsNetwork:
		damage.rpc(damagecount)
	else:
		damage(damagecount)

	area.queue_free()
