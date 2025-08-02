extends CharacterBody2D

@export var health = 10
@export var damagecount = 3

@export var move_speed := 50
@export var direction = Vector2.LEFT

@export var enemy_id: String
@export var color: Color
@export var color_str = "Green"

@onready var animator = $AnimatedSprite2D
@onready var left_floor_check = $left_floor
@onready var left_wall_check = $left_wall

@onready var right_floor_check = $right_floor
@onready var right_wall_check = $right_wall

@export var is_invincible: bool = false
@export var invincibility_time := 1.5  # segundos de invencibilidad
@export var death = false

var path = "user://data.cfg"

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
	
	LoadGameData()

func  _physics_process(delta: float) -> void:
	# Movimiento horizontal
	velocity.x = direction.x * move_speed
		
	# Gravedad
	if not is_on_floor():
		velocity.y += 400 * delta
	else:
		velocity.y = 0
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
func damage(damage):
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
	death = death
	SaveGameData()
	queue_free()
	
func SaveGameData():
	if GameController.IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return 
	
	
	var config = ConfigFile.new()
	var path = "user://data.cfg"

	if config.load(path) != OK:
		print("Creando archivo nuevo de enemigos...")
	
	# GUARDAR salud = 0 para indicar que está muerto
	config.set_value("data3", enemy_id, death)
	config.save(path)
	

func LoadGameData():
	
	if GameController.IsNetwork:
		if !get_tree().get_multiplayer().is_server():
			return

	var config = ConfigFile.new()
	if config.load(path) == OK:
		if config.has_section_key("data2", name + "_ID"):
			enemy_id = config.get_value("data2", name + "_ID")
		else:
			enemy_id = str(randi())
			config.set_value("data2",  name + "_ID", enemy_id)
			config.save(path)
			
	
		if config.get_value("data3", enemy_id, false) == true:
			if GameController.IsNetwork:
				remove_enemy.rpc()
			else:
				remove_enemy()
	
@rpc("any_peer", "call_local")
func remove_enemy():
	queue_free()	
	
func _on_area_2d_area_entered(area: Area2D) -> void:
	if !area.is_in_group("bullet"):
		return
	
	if GameController.IsNetwork:
		damage.rpc( damagecount )
	else:
		damage( damagecount )
	
	area.queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("water"):
		if GameController.IsNetwork:
			damage.rpc( 100 )
		else:
			damage( 100 )
