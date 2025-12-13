extends CharacterBody2D

@export var health = 3
@export var speed = 300  # Velocidad horizontal
@export var jump_count = 0 # Fuerza del salto (valor negativo porque hacia arriba)
@export var jump_count_max = 1 # Fuerza del salto (valor negativo porque hacia arriba)
@export var jump_count_max_air_element = 2 # Fuerza del salto (valor negativo porque hacia arriba)
@export var jump_force = -400  # Fuerza del salto (valor negativo porque hacia arriba)
@export var jump_water_force = -200  # Fuerza del salto (valor negativo porque hacia arriba)
@export var jump_wall_force = 100  # Fuerza del salto (valor negativo porque hacia arriba)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var swim_gravity_factor = 0.25

@export var is_wall_sliding: bool = false
@export var wall_gravity = 100  # Fuerza de gravedad en la pared

@export var is_in_water_or_lava: bool = false

@export var shoot_cooldown = 1.0  # Tiempo entre disparos (en segundos)
@export var shoot_timer = 0.0     # Contador de tiempo

@export var damagecount = 1     # Contador de tiempo

@export var is_invincible: bool = false
@export var invincibility_time := 1.5  # segundos de invencibilidad

@onready var animator = $AnimatedSprite2D
@onready var bulletspawn = $bulletpos/bulletspawn
@onready var bulletpos = $bulletpos
@onready var bulletscene = preload("res://Scenes/bullet.tscn")

@onready var walksounds = $WalkSounds
@onready var damagesounds = $DamageSounds
@onready var shootsounds = $ShootSounds
@onready var jumpsounds = $JumpSounds

@onready var pausemenu = $"Pause menu"
@onready var hud = $Hud
@onready var camera = $Camera2D
@onready var light = $PointLight2D
@onready var lifes = $Hud/Lifes/Label
@onready var energys = $Hud/Energys/Label
@onready var points = $Hud/Points/Label
@onready var username = $Username
@onready var snow = $Snow
@onready var ash = $Ash

@export var id: int = 1
@export var character: String = "fire"

@export var ball_color: Color = Color.WHITE
@export var is_fireball = false
@export var is_shotting = false

func _enter_tree() -> void:
	id = name.to_int()
	set_multiplayer_authority(id)
	RespawnPos()
	
func _ready() -> void:

	username.visible = true
	camera.enabled = is_multiplayer_authority()
	camera.visible = is_multiplayer_authority()
	hud.visible = is_multiplayer_authority()

	
	if is_multiplayer_authority():
		GameController.playernode = self
		username.text = Network.Username
		character = Network.character
		Network.print_role("Multiplayer ID:" + str(multiplayer.get_unique_id()))
		Network.print_role("Node name:" + name)
		Network.print_role("is_multiplayer_authority():" + str(is_multiplayer_authority()))
		

func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	labels_update()
	update_particles()
	update_character()


func labels_update():
	if not is_multiplayer_authority():
		return
		
	lifes.text = str("Lifes: " + str(health))
	energys.text = str("Energys: " + str(GameController.energys))
	points.text = str("Points: " + str(GameController.points))


func update_particles():
	if not is_multiplayer_authority():
		return
		
	if GameController.level > 6 and GameController.level <= 12:
		snow.emitting = false
		ash.emitting = true
	elif GameController.level > 18 and GameController.level <= 24:
		snow.emitting = true
		ash.emitting = false
	else:
		snow.emitting = false
		ash.emitting = false

@rpc("any_peer", "call_local")
func update_character():
	if character == "fire":
		light.color = Color.ORANGE
		ball_color = Color.ORANGE
		is_fireball = true
	elif character == "water":
		light.color = Color.WHITE
		ball_color = Color.BLUE
		is_fireball = false
	elif character == "air":
		light.color = Color.WHITE
		ball_color = Color.DIM_GRAY
		is_fireball = false
	elif character == "earth":
		light.color = Color.WHITE
		ball_color = Color.SADDLE_BROWN
		is_fireball = false

func _physics_process(delta):
	if !is_multiplayer_authority():
		return

	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if is_in_water_or_lava:
		velocity.y += gravity * delta * swim_gravity_factor
	else:
		velocity.y += gravity * delta
		
	if is_on_floor():
		jump_count = 0

	# Movimiento lateral
	velocity.x = direction.x * speed

	Wall(delta)
	Animations(direction)
	flip(direction)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return

	# Teclado / mando para disparar
	if event.is_action_pressed("Shoot0") and not is_shotting:
		shoot()
		get_viewport().set_input_as_handled()

	# Teclado / mando para saltar
	if event.is_action_pressed("jump0"):
		Jump()
		get_viewport().set_input_as_handled()






func Jump():
	if !is_multiplayer_authority():
		return

	if !is_in_water_or_lava and jump_count < jump_count_max:
		velocity.y = jump_force
		jumpsounds.play()
		jump_count += 1
	elif !is_in_water_or_lava and jump_count < jump_count_max_air_element and character == "air":
		velocity.y = jump_force
		jumpsounds.play()
		jump_count += 1

	elif is_in_water_or_lava:
		# Impulso hacia arriba estilo brazada
		velocity.y += jump_water_force
	elif Input.is_action_pressed("ui_right") and is_on_wall():
		velocity.y = jump_force
		velocity.x = -jump_wall_force

		if not is_in_water_or_lava:
			jumpsounds.play()
	elif Input.is_action_pressed("ui_left") and is_on_wall():
		velocity.y = jump_force
		velocity.x = jump_wall_force

		if not is_in_water_or_lava:
			jumpsounds.play()


func Wall(delta: float):
	if !is_multiplayer_authority():
		return

	if is_on_wall() and !is_on_floor():
		if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"):
			is_wall_sliding = true
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false

	if is_wall_sliding:
		velocity.y += (wall_gravity * delta)
		velocity.y = min(velocity.y, wall_gravity)

func Animations(direction: Vector2):
	if !is_multiplayer_authority():
		return

	if is_in_water_or_lava:
		animator.play("%s swim" % [character])
	else:
		# Tu código de animaciones de suelo/aire
		if !is_on_floor():
			if velocity.y < 0:
				animator.play("%s jump" % [character])
			else:
				animator.play("%s fall" % [character])
		elif direction.x != 0:
			animator.play("%s walk" % [character])
		else:
			animator.play("%s idle" % [character])

func flip(direction: Vector2):
	if !is_multiplayer_authority():
		return

	# Voltear sprite
	if direction.x < 0:
		animator.flip_h = true
	elif direction.x > 0:
		animator.flip_h = false

	if velocity.x != 0 and is_on_floor() :
		if !walksounds.playing :
			walksounds.play()
	else:
		if walksounds.playing:
			walksounds.stop()

@rpc("any_peer", "call_local")
# Función para recibir daño
func damage(damage_count: int) -> void:
	
	if is_invincible:
		return

	damagesounds.play()

	health -= damage_count

	GamePersistentData.SavePersistentNodes()
	GameController.GameData.SaveGameData()

	if health <= 0:
		game_over.rpc()
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
func healting(count):
	health += count
	GamePersistentData.SavePersistentNodes()
	GameController.GameData.SaveGameData()

	
func shoot():
	if not is_multiplayer_authority():
		return

	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	var radius = 20.0  # puedes ajustar esto a tu gusto
	bulletpos.global_position = global_position + direction_to_mouse * radius
	bulletpos.look_at(mouse_pos)

	shoot_rpc.rpc(direction_to_mouse, bulletpos.global_rotation, bulletpos.global_position)  # Si está conectado en red


@rpc("any_peer", "call_local")
func shoot_rpc(direction, rotation: float, position: Vector2):

	bulletpos.global_rotation = rotation
	bulletpos.global_position = position
	
	is_shotting = true
	
	shootsounds.play()
	
	var bullet = bulletscene.instantiate()
	bullet.global_position = bulletspawn.global_position
	bullet.direction = direction
	get_parent().add_child(bullet, true)

	bullet.bullet_sprite.modulate = ball_color
	bullet.bullet_light.color = ball_color
	bullet.bullet_light.enabled = is_fireball
	bullet.bullet_fire.visible = is_fireball
	bullet.fireball = is_fireball
	
	await get_tree().create_timer(1).timeout
	
	is_shotting = false


@rpc("any_peer", "call_local")
func load_gameover_scene():
	LoadScene.LoadGameOverMenu(GameController.levelnode)


@rpc("any_peer", "call_local")
func game_over():
	health = 3
	
	RespawnPos()
	
	GamePersistentData.SavePersistentNodes()
	GameController.GameData.SaveGameData()


	load_gameover_scene.rpc()

	
	
func RespawnPos():
	global_position = GameController.SpawnPoint.global_position


func _on_texture_button_pressed() -> void:
	if !is_multiplayer_authority():
		return
			
	pausemenu.visible = !pausemenu.visible

	if multiplayer.multiplayer_peer == null \
	or multiplayer.multiplayer_peer is OfflineMultiplayerPeer \
	or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		get_tree().paused = pausemenu.visible
	
func _on_area_2d_area_entered(area: Area2D) -> void:
	if !is_multiplayer_authority():
		return
		
	if area.is_in_group("bullet"):
		damage.rpc(damagecount)
		Network.remove_node_synced.rpc(area.get_path())
	elif area.is_in_group("box"):
		GameController.getlevel.rpc()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if !is_multiplayer_authority():
		return
	
	if body.is_in_group("enemy"):
		damage.rpc(damagecount)

		
	elif body.is_in_group("water"):
		is_in_water_or_lava = true

		if character == "water":
			return 
		
		is_invincible = false
		
		damage.rpc(health)
	elif body.is_in_group("lava"):
		is_in_water_or_lava = true

		if character == "fire":
			return 
		
		is_invincible = false
		
		damage.rpc(health)
	elif body.is_in_group("acid"):
		is_in_water_or_lava = true
		is_invincible = false
		
		damage.rpc(health)

	elif body.is_in_group("mud"):
		is_in_water_or_lava = true
		is_invincible = false

		if character == "earth":
			return 
		
		damage.rpc(health)
		
	elif body.is_in_group("box"):
		GameController.getlevel.rpc()


func _on_area_2d_body_exited(body:Node2D) -> void:
	if body.is_in_group("water"):
		is_in_water_or_lava = false
	elif body.is_in_group("lava"):
		is_in_water_or_lava = false
	elif body.is_in_group("acid"):
		is_in_water_or_lava = false
	elif body.is_in_group("mud"):
		is_in_water_or_lava = false
