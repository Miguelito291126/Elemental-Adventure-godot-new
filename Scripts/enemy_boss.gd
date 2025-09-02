extends CharacterBody2D

@export var health = 100
@export var damagecount = 5

@onready var healthbar = $ProgressBar


@onready var bulletscene = preload("res://Scenes/bullet.tscn")
@onready var firescene = preload("res://Scenes/fire.tscn")
@onready var bulletspawn = $bulletpos/bulletspawn
@onready var bulletpos = $bulletpos
@onready var shoot_timer = $Timer  # Asegúrate de poner el nombre correcto del Timer
@export var color: Color
@export var color_str = "Green"

@export var is_invincible: bool = false
@export var invincibility_time := 1.5  # segundos de invencibilidad

@onready var animator = $AnimatedSprite2D

@export var enemy_id: String
@export var death = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var is_burning: bool = false

func _ready() -> void:
	if color_str == "Green":
		if !animator.is_playing():
			animator.play("idle slime green")
	elif color_str == "Blue":
		if !animator.is_playing():
			animator.play("idle slime blue")
	elif color_str == "Yellow":
		if !animator.is_playing():
			animator.play("idle slime yellow")
	elif color_str == "Orange":
		if !animator.is_playing():
			animator.play("idle slime orange")
		
	$PointLight2D.enabled = color_str == "Orange"
	$PointLight2D.color = color
	
	healthbar.max_value = health
	healthbar.value = health


@rpc("any_peer", "call_local")
func damage(damage_count: int):
	if is_invincible:
		return

	health -= damage_count
	healthbar.value = health
	
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
	var blink_timer := Timer.new()
	blink_timer.wait_time = invincibility_time
	blink_timer.one_shot = true
	add_child(blink_timer)
	blink_timer.start()
	
	var blink_time := 0.1
	var elapsed := 0.0
	var total_time := 0.0

	# Guardar el color original
	var original_modulate := Color.WHITE

	# Efecto de parpadeo rojo-blanco
	while total_time < invincibility_time:
		modulate = Color.RED
		await get_tree().create_timer(blink_time).timeout
		modulate = Color.WHITE
		await get_tree().create_timer(blink_time).timeout
		total_time += blink_time * 2

	# Restaurar color original y terminar invencibilidad
	modulate = original_modulate
	is_invincible = false
	
@rpc("any_peer", "call_local")
func kill():
	death = !death

	# Posición donde aparecerán los objetos (cerca del jugador)
	var drop_position = global_position + Vector2(randf_range(-16,16), randf_range(-16,16))

	# Decidir aleatoriamente qué soltar
	var drop_chance = randi() % 2  # 0 o 1
	if drop_chance == 0:
		var coin = preload("res://scenes/energy.tscn").instantiate()
		coin.global_position = drop_position
		get_parent().add_child(coin)
	else:
		var health = preload("res://scenes/hearth.tscn").instantiate()
		health.global_position = drop_position
		get_parent().add_child(health)
		
	GameController.SavePersistentNodes()
	GameController.SaveGameData()
	queue_free()

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	move_and_slide()

	
func _process(_delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player_pos = players[0].global_position
		bulletpos.look_at(player_pos)  # Esto sigue siendo útil para apuntar el cañón
		


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

	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		MusicManager.is_near_boss = true
	
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
		if color_str == "Green":
			animator.play("attack slime green")
		elif color_str == "Blue":
			animator.play("attack slime blue")
		elif color_str == "Yellow":
			animator.play("idle slime yellow")
		elif color_str == "Orange":
			animator.play("attack slime orange")
			
		shoot_timer.start()
		
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		MusicManager.is_near_boss = false
			
		if color_str == "Green":
			animator.play("idle slime green")
		elif color_str == "Blue":
			animator.play("idle slime blue")
		elif color_str == "Yellow":
			animator.play("idle slime yellow")
		elif color_str == "Orange":
			animator.play("idle slime orange")
				
		shoot_timer.stop()

func _on_shoot_timer_timeout() -> void:
	if GameController.IsNetwork:
		if !get_tree().get_multiplayer().is_server():
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
func shoot(direction):
	var bullet = bulletscene.instantiate()
	bullet.global_position = bulletspawn.global_position
	bullet.direction = direction
	bullet.modulate = color
	bullet.get_node("PointLight2D").color = color
	bullet.get_node("PointLight2D").enabled = color_str == "Orange"
	bullet.get_node("Fire").visible = color_str == "Orange"
	bullet.fireball = color_str == "Orange"
	

	get_parent().add_child(bullet, true)


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
		if GameController.IsNetwork:
			damage.rpc( damagecount )
		else:
			damage( damagecount )

	is_burning = false	
	fire.queue_free()

func _on_area_2d_2_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet"):
		if GameController.IsNetwork:
			damage.rpc( damagecount )
		else:
			damage( damagecount )

		if area.fireball:
			burn()



func _on_area_2d_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("water"):
		if color_str == "Blue":
			return
		
		is_invincible = false
		
		if GameController.IsNetwork:
			damage.rpc(health)
		else:
			damage(health)
	elif body.is_in_group("lava"):
		if color_str == "Orange":
			return

		is_invincible = false
		
		if GameController.IsNetwork:
			damage.rpc(health)
		else:
			damage(health)
	elif body.is_in_group("acid"):
		is_invincible = false
		
		if GameController.IsNetwork:
			damage.rpc(health)
		else:
			damage(health)
