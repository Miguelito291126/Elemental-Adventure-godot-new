extends CharacterBody2D

@export var health = 3
@export var speed = 300  # Velocidad horizontal
@export var jump_force = -400  # Fuerza del salto (valor negativo porque hacia arriba)
@export var gravity = 900  # Valor positivo, gravedad hacia abajo

@export var shoot_cooldown = 1.0  # Tiempo entre disparos (en segundos)
@export var shoot_timer = 0.0     # Contador de tiempo

@export var damagecount = 1     # Contador de tiempo

var is_invincible: bool = false
var invincibility_time := 1.5  # segundos de invencibilidad

@onready var animator = $AnimatedSprite2D
@onready var bulletspawn = $bulletpos/bulletspawn
@onready var bulletpos = $bulletpos
@onready var bulletscene = preload("res://Scenes/bullet.tscn")

@onready var walksounds = $WalkSounds
@onready var shootsounds = $ShootSounds
@onready var jumpsounds = $JumpSounds

@onready var pausemenu = $"Pause menu"
@onready var hud = $Hud
@onready var camera = $Camera2D
@onready var light = $PointLight2D
@onready var lifes = $Hud/Lifes/Label
@onready var energys = $Hud/Energys/Label
@onready var points = $Hud/Points/Label

@export var id: String

@export var ball_color: Color = Color.WHITE
@export var fireball: bool = false
@export var is_shotting = false

func _enter_tree() -> void:
	if GameController.IsNetwork:
		set_multiplayer_authority(name.to_int())
	
	RespawnPos()
	
func _ready() -> void:
	if GameController.IsNetwork:
		camera.enabled = is_multiplayer_authority()
		camera.visible = is_multiplayer_authority()
		hud.visible = is_multiplayer_authority()
	
		if !is_multiplayer_authority():
			return
			
		print("Multiplayer ID:", multiplayer.get_unique_id())
		print("Node name:", name)
		print("is_multiplayer_authority():", is_multiplayer_authority())
	
	GameController.playernode = self
	
	if GameController.character == "fire":
		light.color = Color.ORANGE
		ball_color = Color.ORANGE
		fireball = true
	elif GameController.character == "water":
		light.color = Color.WHITE
		ball_color = Color.BLUE
		fireball = false
	elif GameController.character == "air":
		light.color = Color.WHITE
		ball_color = Color.DIM_GRAY
		fireball = false
	elif GameController.character == "earth":
		light.color = Color.WHITE
		ball_color = Color.SADDLE_BROWN
		fireball = false
	
func _process(delta: float) -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
		
	lifes.text = "Lifes: " + str(health)
	energys.text = "Energys: " + str(GameController.energys)
	points.text = "Points: " + str(GameController.points)

func _physics_process(delta):
	
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
		
	# Aplicar gravedad
	velocity.y += gravity * delta

	# Movimiento lateral
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").x
	velocity.x = direction * speed

	# Voltear sprite
	animator.flip_h = direction < 0
	
	if direction != 0 and is_on_floor():
		if !walksounds.playing:
			walksounds.play()
	else:
		if walksounds.playing:
			walksounds.stop()

	# Saltar (solo si está en el suelo)
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_force
		jumpsounds.play()
	
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	var radius = 20.0  # puedes ajustar esto a tu gusto
	bulletpos.global_position = global_position + direction_to_mouse * radius
	bulletpos.look_at(mouse_pos)
	
	if Input.is_action_just_pressed("Shoot0") and not is_shotting:
		if GameController.IsNetwork:
			if is_multiplayer_authority():
				shoot.rpc(direction_to_mouse)  # Si está conectado en red
		else:
			shoot(direction_to_mouse)

	# ANIMACIONES según estado
	if !is_on_floor():
		if velocity.y < 0:
			animator.play("%s jump" % [GameController.character])  # Subiendo
		else:
			animator.play("%s fall" % [GameController.character])  # Bajando
	elif direction != 0:
		animator.play("%s walk" % [GameController.character])     # Caminando en suelo
	else:
		animator.play("%s idle" % [GameController.character])     # Quieto en suelo

	move_and_slide()

@rpc("any_peer", "call_local")
# Función para recibir daño
func damage(damage):
	
	if is_invincible:
		return
		
	health -= damage
	
	GameController.SavePersistentNodes()
	GameController.SaveGameData()
		
	if health <= 0:
		if GameController.IsNetwork:
			game_over.rpc()
		else:
			game_over()
	else:
		if GameController.IsNetwork:
			start_invincibility.rpc()
		else:
			start_invincibility()
	

func SaveGameData():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"health" : health
	}
	return save_dict

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
func healting(count):
	health += count
	GameController.SavePersistentNodes()
	GameController.SaveGameData()
		

@rpc("any_peer", "call_local")
func shoot(direction):
	is_shotting = true
	
	shootsounds.play()
	
	var bullet = bulletscene.instantiate()
	bullet.global_position = bulletspawn.global_position
	bullet.direction = direction
	bullet.modulate = ball_color
	bullet.get_node("PointLight2D").enabled = fireball
	bullet.get_node("PointLight2D").color = ball_color
	bullet.get_node("Fire").visible = fireball
	
	get_parent().add_child(bullet, true)
	
	await get_tree().create_timer(1).timeout
	
	is_shotting = false
	
@rpc("any_peer", "call_local")
func game_over():
	health = 3
	
	RespawnPos()
	
	GameController.SavePersistentNodes()
	GameController.SaveGameData()
	
	if GameController.IsNetwork:
		GameController.LoadGameOverMenu.rpc()
	else:
		GameController.LoadGameOverMenu()
	
	
	
func RespawnPos():
	global_position = GameController.spawner.global_position


func _on_texture_button_pressed() -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
			
	pausemenu.visible = !pausemenu.visible
	
func _on_area_2d_area_entered(area: Area2D) -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
		
	if area.is_in_group("bullet"):
		if GameController.IsNetwork:
			damage.rpc(damagecount)
		else:
			damage(damagecount)
		
		area.queue_free()
	elif area.is_in_group("box"):
		if GameController.IsNetwork:
			GameController.getlevel.rpc()
		else:
			GameController.getlevel()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if GameController.IsNetwork:
		if !is_multiplayer_authority():
			return
	
	if body.is_in_group("enemy"):
		if GameController.IsNetwork:
			damage.rpc(damagecount)
		else:
			damage(damagecount)
		
	elif body.is_in_group("water"):
		if GameController.character == "water":
			return 
			
		if GameController.IsNetwork:
			damage.rpc(3)
		else:
			damage(3)
	elif body.is_in_group("lava"):
		if GameController.character == "fire":
			return 
			
		if GameController.IsNetwork:
			damage.rpc(3)
		else:
			damage(3)
	elif body.is_in_group("acid"):
		if GameController.IsNetwork:
			damage.rpc(3)
		else:
			damage(3)
