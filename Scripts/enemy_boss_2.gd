extends CharacterBody2D

enum {
	walk,
	idle,
	attack
}

@export var Max_Hearth = 1000
@export var hearth = Max_Hearth 
@export var can_move = true

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var InvunerabilityTime = $Invunerability
@onready var Animation_Effects = $AnimationPlayer
@onready var Animation_sprite = $AnimatedSprite2D
@onready var marker_node = $Node2D/Marker2D
@onready var marker_node_parent = $Node2D

var state = idle

var can_fire = true

@onready var player

var fancing_left = false

var play_boss_music = false

var slimeballs = preload("res://Scenes/fireball.tscn")

var rng = RandomNumberGenerator.new()

var hearths = preload("res://Scenes/hearth.tscn")
var energys = preload("res://Scenes/energy.tscn")

@export var speed = 100
@export var max_speed = 70
@export var max_speed_in_air = 60
@export var max_speed_in_water = 20
@export var max_speed_in_lava = 100

func _ready():
	setlifes(hearth)

func damage(ammount):
	if can_move == true:
		can_move = false
		if InvunerabilityTime.is_stopped():
			Animation_sprite.stop()
			InvunerabilityTime.start()
			setlifes(hearth - ammount)
			Animation_Effects.play("damage")
			Animation_Effects.queue("flash")

func drop_hearths():
	var new_hearth = hearths.instantiate()
	get_parent().add_child(new_hearth)
	new_hearth.position = position
	new_hearth.freeze = false

	
func drop_energys():
	var new_energy = energys.instantiate()
	get_parent().add_child(new_energy)
	new_energy.position = position
	new_energy.freeze = false
			

func setlifes(value):
	hearth = clamp(value,0,Max_Hearth)
	if hearth <= 0:
		print("boss dead")
		rng.randomize()
		
		if player:
			player.score += 5
		
		queue_free()
		var parent = get_parent()
		parent.get_node("Level Music2").stop()
		parent.get_node("Level Music").play()

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
		get_parent().add_child(slime_ball)
		
		slime_ball.get_node("PointLight2D").enabled = Globals.Graphics
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
		slime_ball.modulate = Color("Orange")
		slime_ball.scale = Vector2(2, 2)
		
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
			velocity.y += gravity * delta
		
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

func _on_detection_area_2_body_entered(body:Node2D):
	if body.is_in_group("player"):
		body.damage(1)

func _on_detection_area_body_entered(body:Node2D):
	if body.is_in_group("player"):
		state = attack
		var parent = get_parent()
		if not play_boss_music:
			parent.get_node("Level Music2").play()
			parent.get_node("Level Music").stop()
			play_boss_music = true
		


func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		state = idle



func _on_detection_area_3_body_entered(body:Node2D):
	if body.is_in_group("player"):
		player = body


func _on_detection_area_3_body_exited(body:Node2D):
	if body.is_in_group("player"):
		player = null
