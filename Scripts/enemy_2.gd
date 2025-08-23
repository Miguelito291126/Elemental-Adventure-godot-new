extends CharacterBody2D

enum {
	walk,
	idle,
	attack
}

@export var Max_Hearth = 100
@export var hearth = Max_Hearth 
@export var can_move = true

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var InvunerabilityTime = $Invunerability
@onready var Animation_Effects = $AnimationPlayer
@onready var Animation_sprite = $AnimatedSprite2D
@onready var marker_node = $Node2D/Marker2D
@onready var marker_node_parent = $Node2D

var state = walk

var can_fire = true

@onready var player

var fancing_left = false

var slimeballs = preload("res://Scenes/fireball.tscn")

var rng = RandomNumberGenerator.new()

var hearths = preload("res://Scenes/hearth.tscn")
var energys = preload("res://Scenes/energy.tscn")

@export var speed = 100
@export var max_speed = 70
@export var max_speed_in_air = 60
@export var max_speed_in_water = 20
@export var max_speed_in_lava = 100

@export var gravity_swim = 0.25
@export var velocity_swim = 80.0

var random_number = 0

var is_in_water = false
var is_in_lava = false

func _ready():
	setlifes(hearth )

	if Network.is_networking:
		if multiplayer.is_server():
			rng.randomize()
			random_number = rng.randi_range(0,  1)
			set_random_vars.rpc(random_number)
			


func damage(ammount):
	if can_move == true:
		can_move = false
		if InvunerabilityTime.is_stopped():
			Animation_sprite.stop()
			InvunerabilityTime.start()
			setlifes(hearth - ammount)
			Animation_Effects.play("damage")
			Animation_Effects.queue("flash")



func drop_hearths(position):
	var new_hearth = hearths.instantiate()
	get_parent().add_child(new_hearth, true)
	new_hearth.position = position

func drop_energys(position):
	var new_energy = energys.instantiate()
	get_parent().add_child(new_energy, true)
	new_energy.position = position

func generate_random_vars():
	rng.randomize()
	random_number = rng.randi_range(0,  5)

@rpc("call_local", "any_peer")
func set_random_vars(random_num):
	random_number = random_num

@rpc("call_local", "any_peer")
func drop_item(item_type, position):
	print("Dropping", item_type, "at:", position)
	# Verificar el tipo de objeto a dejar caer y crear el objeto correspondiente
	if item_type == "hearth":
		drop_hearths(position)
	elif item_type == "energy":
		drop_energys(position)

func setlifes(value):
	hearth = clamp(value,0,Max_Hearth)
	if hearth <= 0:
		print("enemy dead")
		var table = ["energy", "hearth"]
		
		if Network.is_networking:
			if multiplayer.is_server():
				set_random_vars.rpc(random_number)

				
			if random_number == null: return 
			var drop_type = table[random_number] 
			drop_item.rpc(drop_type, self.position)		
		else:
			rng.randomize()
			random_number = rng.randi_range(0,  1)
			var drop_type = table[random_number] 
			drop_item(drop_type, self.position)

		if player:
			player.score += 3

		queue_free()

func flip():
	fancing_left = !fancing_left

	Animation_sprite.scale.x = Animation_sprite.scale.x * -1
	if fancing_left:
		speed = abs(speed) * -1
	else:
		speed =  abs(speed)

func simelball(bullet_direction, bullet_pos, bullet_speed):
	if can_fire:
		var slime_ball = slimeballs.instantiate()
		get_parent().add_child(slime_ball, true)
		
		slime_ball.get_node("PointLight2D").enabled = false
		slime_ball.get_node("PointLight2D").shadow_enabled = Globals.Graphics
		slime_ball.get_node("PointLight2D").shadow_filter_smooth = 4 - Globals.Graphics

		if Globals.Graphics == 0:
			slime_ball.get_node("PointLight2D").shadow_filter = 0
		elif Globals.Graphics == 2:
			slime_ball.get_node("PointLight2D").shadow_filter = 1
		elif Globals.Graphics == 3:
			slime_ball.get_node("PointLight2D").shadow_filter = 2
		else:
			if Globals.Graphics > 3 :
				slime_ball.get_node("PointLight2D").shadow_filter = 2
			elif Globals.Graphics < 0:
				slime_ball.get_node("PointLight2D").shadow_filter = 0
			else:
				slime_ball.get_node("PointLight2D").shadow_filter = 1


		slime_ball.get_node("Fire").emitting = false
		slime_ball.modulate = Color("Blue")
		
		slime_ball.set_rotation(bullet_direction)
		slime_ball.set_global_position(bullet_pos)
		slime_ball.velocity = Vector2(bullet_speed, 0).rotated(bullet_direction)
		
		can_fire = false
		await get_tree().create_timer(0.8).timeout
		can_fire = true

func _physics_process(delta):
	update_hearths()


	if can_move == true:
		if not is_on_floor():
			if !is_in_water or !is_in_lava:
				velocity.y += gravity * delta
			else:
				velocity.y = clampf(velocity.y + (gravity * delta * gravity_swim), -10000, velocity_swim)
		
		if player:
			marker_node_parent.look_at(player.global_position)

		match state:
			idle:
				Animation_sprite.animation = "idle"
				velocity.x = 0
			walk:
				
				if is_on_wall() or not $Abajo_detector_derecha.is_colliding() or not $Abajo_detector_izquierda.is_colliding() and is_on_floor():
					flip()
				
				Animation_sprite.animation = "walk"
				velocity.x = speed
			attack:
				Animation_sprite.animation = "attack"
				velocity.x = 0		
				simelball(marker_node_parent.get_rotation(), marker_node.get_global_position(), 500)
		
		move_and_slide()

func update_hearths():
	var progresvar = $ProgressBar

	progresvar.value = hearth
	if hearth >= Max_Hearth:
		progresvar.visible = false
	else:
		progresvar.visible = true


func _on_invunerability_timeout():
	Animation_Effects.play("rest")
	Animation_sprite.play("walk")
	can_move = true

func _on_detection_area_2_body_entered(body):
	if body.is_in_group("player"):
		if Network.is_networking:
			body.damage.rpc(1)
		else:
			body.damage(1)

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		state = attack
		
func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		state = walk

func _on_detection_area_3_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_area_3_body_exited(body):
	if body.is_in_group("player"):
		player = null
		
		
func in_water():
	pass

func out_water():
	pass

func out_lava():
	pass

func in_lava():
	damage(Max_Hearth)
		
func save_state():
	return {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"name" : name,
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"size_x" : scale.x,
		"size_y" : scale.y,
		"enemy_hearth" : hearth,
	}
	
func load_state(info):
	name = info.name
	position = Vector2(info.pos_x, info.pos_y)
	hearth = info.enemy_hearth


func _on_water_detector_2d_body_entered(_body:Node2D):
	in_water()


func _on_water_detector_2d_body_exited(_body:Node2D):
	out_water()


func _on_lava_detector_2d_body_entered(_body:Node2D):
	in_lava()


func _on_lava_detector_2d_body_exited(_body:Node2D):
	out_lava()
