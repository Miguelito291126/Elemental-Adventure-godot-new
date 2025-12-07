extends CharacterBody2D

@export var health = 10
@export var damagecount = 3

@onready var bulletscene = preload("res://Scenes/bullet.tscn")
@onready var firescene = preload("res://Scenes/fire.tscn")
@onready var bulletspawn = $bulletpos/bulletspawn
@onready var bulletpos = $bulletpos
@onready var shoot_timer = $Timer  # Asegúrate de poner el nombre correcto del Timer
@export var color: Color
@export var direction = Vector2.LEFT
@export var move_speed = 50

@export var is_shooting = false


@export var is_invincible: bool = false
@export var invincibility_time = 1.5  # segundos de invencibilidad

@onready var animator = $AnimatedSprite2D
@onready var left_floor_check = $left_floor
@onready var left_wall_check = $left_wall

@onready var right_floor_check = $right_floor
@onready var right_wall_check = $right_wall

@export var death = false

@export var is_burning: bool = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	animator.play("robot 2 walk")
	
	$PointLight2D.color = color
	
		
@rpc("any_peer", "call_local")
func damage(damage_count: int):
	if is_invincible:
		return

	health -= damage_count

	if health <= 0:
		kill.rpc()
	else:
		start_invincibility.rpc()


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

	GamePersistentData.SavePersistentNodes()
	GameController.GameData.SaveGameData()
	Network.add_queue_free_nodes(self.get_path())
		
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
	

func  _physics_process(delta: float) -> void:
	if is_shooting:
		velocity = Vector2.ZERO  # Se detiene al disparar
		move_and_slide()
		
		return


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
	
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_shooting = true
		animator.play("robot 2 shot")
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
		shoot_timer.start()
		
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_shooting = false
		animator.play("robot 2 walk")
		shoot_timer.stop()

func _on_shoot_timer_timeout() -> void:

	if !multiplayer.is_server():
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
		shoot.rpc(direction_to_player)

@rpc("any_peer", "call_local")
func shoot(direction):
	var bullet = bulletscene.instantiate()
	bullet.global_position = bulletspawn.global_position
	bullet.direction = direction
	bullet.fireball = false

	get_parent().add_child(bullet, true)

	bullet.bullet_sprite.modulate = color
	bullet.bullet_light.color = color
	bullet.bullet_light.enabled = true
	bullet.bullet_fire.visible = false

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
		damage.rpc( damagecount )

	is_burning = false	
	fire.queue_free()

func _on_area_2d_2_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet"):

		damage.rpc( damagecount )
	
		if area.fireball:
			burn()


func _on_area_2d_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("water"):
		is_invincible = false
		damage.rpc(health)
	elif body.is_in_group("lava"):
		is_invincible = false
		damage.rpc(health)
	elif body.is_in_group("acid"):
		is_invincible = false
		damage.rpc(health)

	elif body.is_in_group("mud"):
		is_invincible = false
		damage.rpc(health)

