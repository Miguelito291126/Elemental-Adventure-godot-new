extends CharacterBody2D

@export var health = 10
@export var damagecount = 3

@onready var bulletscene = preload("res://Scenes/bullet.tscn")
@onready var firescene = preload("res://Scenes/fire.tscn")
@onready var bulletspawn = $bulletpos/bulletspawn
@onready var bulletpos = $bulletpos
@onready var shoot_timer = $Timer  # Asegúrate de poner el nombre correcto del Timer
@export var color: Color
@onready var animator = $AnimatedSprite2D

@export var is_invincible: bool = false
@export var invincibility_time = 1.5  # segundos de invencibilidad

@export var death = false

@export var is_burning: bool = false

func _ready() -> void:
	$PointLight2D.color = color
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	if color == Color.RED:
		if !animator.is_playing():
			animator.play("robot Idle")
	elif color == Color.BLUE:
		if !animator.is_playing():
			animator.play("robot 3 Idle")
			
		
@rpc("any_peer", "call_local")
func damage(damage_count: int):
	if is_invincible:
		return

	health -= damage_count

	if health <= 0:
		call_deferred("kill")
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

func kill():
	if not multiplayer.is_server():
		return

	if death:
		return  # Evita ejecutar 2 veces la muerte

	death = !death

	# Posición donde aparecerán los objetos (cerca del jugador)
	var drop_position = global_position
	# Decidir aleatoriamente qué soltar
	var drop_chance = randi() % 2  # 0 o 1
	
	if drop_chance == 0:
		var coin = load("res://Scenes/energy.tscn").instantiate()
		coin.global_position = drop_position
		get_parent().add_child(coin)  # El MultiplayerSpawner manejará la replicación
	else:
		var hearth = load("res://Scenes/hearth.tscn").instantiate()
		hearth.global_position = drop_position
		get_parent().add_child(hearth)  # El MultiplayerSpawner manejará la replicación

	GamePersistentData.SavePersistentNodes()
	GameController.GameData.SaveGameData()
	Network.add_queue_free_nodes(self.get_path())
	Network.remove_node_synced.rpc(get_path())


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

func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
		
	var players = get_tree().get_nodes_in_group("player")
	var closest_player = players[0]
	var closest_distance = global_position.distance_to(closest_player.global_position)

	if players.size() == 0:
		return

	for p in players:
		if not p or not p.is_inside_tree():
			continue
			
		var distance = global_position.distance_to(p.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_player = p

	if closest_player:
		var player_pos = closest_player.global_position
		animator.flip_h = player_pos.x >= global_position.x

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		shoot_timer.start()
		
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		shoot_timer.stop()

func _on_shoot_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var closest_player = players[0]
	var closest_distance = global_position.distance_to(closest_player.global_position)

	for p in players:
		if not p or not p.is_inside_tree():
			continue
			
		var distance = global_position.distance_to(p.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_player = p

	if closest_player:
		var player_pos = closest_player.global_position
		var direction_to_player = (player_pos - global_position).normalized()
		bulletpos.look_at(player_pos)
		shoot.rpc(direction_to_player, bulletpos.global_rotation, bulletpos.global_position)

@rpc("any_peer", "call_local")
func shoot(direction: Vector2, rotation: float, position: Vector2):
	bulletpos.global_rotation = rotation
	bulletpos.global_position = position
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
