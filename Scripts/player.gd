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

func _enter_tree() -> void:
	if GameController.IsNetwork:
		set_multiplayer_authority(name.to_int())
	
func _ready() -> void:
	if GameController.IsNetwork:
		camera.enabled = is_multiplayer_authority()
		camera.visible = is_multiplayer_authority()
		hud.visible = is_multiplayer_authority()
		
		print("Multiplayer ID:", multiplayer.get_unique_id())
		print("Node name:", name)
		print("is_multiplayer_authority():", is_multiplayer_authority())
	
		if !is_multiplayer_authority():
			return
		
		
	GameController.playernode = self
		
	if GameController.character == "fire":
		light.color = Color.ORANGE
	elif GameController.character == "water":
		light.color = Color.WHITE
	elif GameController.character == "air":
		light.color = Color.WHITE
	elif GameController.character == "earth":
		light.color = Color.WHITE
	
	if GameController.IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return 
	
	# Solo cargar datos si no vienes desde el menú
	if GameController.character != "":
		var config = ConfigFile.new()
		if config.load("user://data.cfg") == OK:
			health = config.get_value("data", "health", 3)
		
	
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
		
	shoot_timer -= delta  # Reducir el tiempo restante
	
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	var radius = 20.0  # puedes ajustar esto a tu gusto
	bulletpos.global_position = global_position + direction_to_mouse * radius
	bulletpos.look_at(mouse_pos)

	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and shoot_timer <= 0:

		if GameController.IsNetwork:
			shoot.rpc(direction_to_mouse)  # Si está conectado en red
		else:
			shoot(direction_to_mouse)

		shoot_timer = shoot_cooldown  # Reiniciar el tiempo entre disparos

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
	
	if GameController.IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return 
	
	var config = ConfigFile.new()
	var path = "user://data.cfg"
	config.load(path)
	if health > 0:
		config.set_value("data", "health", health)
		config.save(path)
	
	


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

	if GameController.IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return 
	
	var config = ConfigFile.new()
	var path = "user://data.cfg"
	config.load(path)
	if health > 0:
		config.set_value("data", "health", health)
		config.save(path)
		

@rpc("any_peer", "call_local")
func shoot(direction):
	shootsounds.play()
	
	var bullet = bulletscene.instantiate()
	bullet.global_position = bulletspawn.global_position
	bullet.direction = direction
	
	
	if GameController.character == "fire":
		bullet.modulate = Color.ORANGE
		bullet.get_node("PointLight2D").enabled = true
		bullet.get_node("PointLight2D").color = Color.ORANGE
		bullet.get_node("Fire").visible = true
	elif GameController.character == "water":
		bullet.modulate = Color.BLUE
		bullet.get_node("PointLight2D").enabled = false
		bullet.get_node("Fire").visible = false
	elif GameController.character == "air":
		bullet.modulate = Color.DIM_GRAY
		bullet.get_node("PointLight2D").enabled = false
		bullet.get_node("Fire").visible = false
	elif GameController.character == "earth":
		bullet.modulate = Color.SADDLE_BROWN
		bullet.get_node("PointLight2D").enabled = false
		bullet.get_node("Fire").visible = false
	
	get_parent().add_child(bullet, true)
	
@rpc("any_peer", "call_local")
func game_over():
	health = 3
	
	if GameController.IsNetwork:
		GameController.LoadGameOverMenu.rpc()
	else:
		GameController.LoadGameOverMenu()
	
	if GameController.IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return 

	var config = ConfigFile.new()
	var path = "user://data.cfg"
	config.load(path)
	if health > 0:
		config.set_value("data", "health", health)
		config.save(path)
		


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
		if GameController.IsNetwork:
			damage.rpc(3)
		else:
			damage(3)
