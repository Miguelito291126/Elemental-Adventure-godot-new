extends CharacterBody2D

@export var health = 10
@export var damagecount = 3

@export var move_speed = 50
@export var direction = Vector2.LEFT

@export var color: Color
@export var color_str = "Green"

@onready var firescene = preload("res://Scenes/fire.tscn")

@onready var animator = $AnimatedSprite2D
@onready var left_floor_check = $left_floor
@onready var left_wall_check = $left_wall

@onready var right_floor_check = $right_floor
@onready var right_wall_check = $right_wall

@export var is_invincible: bool = false
@export var invincibility_time = 1.5  # segundos de invencibilidad
@export var death = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var is_burning: bool = false

func _ready() -> void:
	if color_str == "Green":
		animator.play("walk slime green")
	elif color_str == "Blue":
		animator.play("walk slime blue")
	elif color_str == "Yellow":
		animator.play("walk slime yellow")
	elif color_str == "Orange":
		animator.play("walk slime orange")
		
	$PointLight2D.enabled = color_str == "Orange"
	$PointLight2D.color = color
	
	

func  _physics_process(delta: float) -> void:
	# Movimiento horizontal
	velocity.x = direction.x * move_speed
	velocity.y += gravity * delta

	
	# Si el raycast no detecta suelo → girar
	# Detectar borde o pared para girar
	if (not left_floor_check.is_colliding() or left_wall_check.is_colliding()):
		flip_direction()
	elif (not right_floor_check.is_colliding() or right_wall_check.is_colliding()):
		flip_direction()
	
	move_and_slide()
	
func flip_direction():
	direction *= -1
	scale.x *= -1

@rpc("any_peer", "call_local")
func damage(damage_count: int):
	if is_invincible:
		return

	health -= damage_count

	if Network.IsNetwork:
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
	var blink_timer := Timer.new()
	blink_timer.wait_time = invincibility_time
	blink_timer.one_shot = true
	add_child(blink_timer)
	blink_timer.start()
	
	var blink_time := 0.1
	var total_time := 0.0

	# Guardar el color original
	var original_modulate := Color.WHITE

	# Efecto de parpadeo rojo-blanco
	while total_time < invincibility_time:
		animator.modulate = Color.RED
		await get_tree().create_timer(blink_time).timeout
		animator.modulate = Color.WHITE
		await get_tree().create_timer(blink_time).timeout
		total_time += blink_time * 2

	# Restaurar color original y terminar invencibilidad
	animator.modulate = original_modulate
	is_invincible = false
	
@rpc("any_peer", "call_local")
func kill():
	death = !death

	# Posición donde aparecerán los objetos (cerca del jugador)
	var drop_position = global_position
	# Decidir aleatoriamente qué soltar
	var drop_chance = randi() % 2  # 0 o 1
	if drop_chance == 0:
		var coin = load("res://Scenes/energy.tscn").instantiate()
		coin.global_position = drop_position
		get_parent().add_child(coin)
	else:
		var hearth = load("res://Scenes/hearth.tscn").instantiate()
		hearth.global_position = drop_position
		get_parent().add_child(hearth)

	GameData.SavePersistentNodes()
	GameData.SaveGameData()
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

func burn():
	if is_burning:
		return

	is_burning = true

	var fire = firescene.instantiate()
	fire.position = Vector2.ZERO  # se queda en el centro del nodo actual
	add_child(fire)

	# se quema durante 10 segundos
	for i in range(10): # 10 ticks (1 daño por segundo)
		if not is_burning:
			break
		
		await get_tree().create_timer(1.0).timeout
		if Network.IsNetwork:
			damage.rpc( damagecount )
		else:
			damage( damagecount )

	is_burning = false	
	fire.queue_free()
	
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet"):
		if Network.IsNetwork:
			damage.rpc( damagecount )
		else:
			damage( damagecount )

		if area.fireball and color_str != "Orange":
			burn()



func _on_area_2d_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("water"):
		if color_str == "Blue":
			return
 
		is_invincible = false
		
		if Network.IsNetwork:
			damage.rpc(health)
		else:
			damage(health)
	elif body.is_in_group("lava"):
		if color_str == "Orange":
			return
		
		is_invincible = false
		
		if Network.IsNetwork:
			damage.rpc(health)
		else:
			damage(health)
	elif body.is_in_group("acid"):
		is_invincible = false
		
		if Network.IsNetwork:
			damage.rpc(health)
		else:
			damage(health)
