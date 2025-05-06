extends CharacterBody2D

# Variables for movement
var speed = 35
var wander_speed = 15
var player_chase = false
var player = null
var wander_target = Vector2.ZERO
var wander_time = 0
var wander_interval = 3
var pause_time = 0
var pause_duration = 2

# Variables for Health
var current_health = 1
var is_dead = false

# Audio references
@onready var audio_death: AudioStreamPlayer2D = $audio/audio_death

# Variables for Shooting
var can_shoot = true
var shoot_interval = 2.0
var projectile_speed = 200
var shooting_range = 200

# References to nodes
@onready var animated_sprite_2d: AnimatedSprite2D = $animated_sprite_bug_flying_shooter
@onready var ray_cast: RayCast2D = $detection_ray
@onready var detection_area: Area2D = $detection_area
@onready var hit_box: HitBox = $hit_box
@onready var shoot_timer: Timer = $shoot_timer

# Preload the projectile scene
var Projectile = preload("res://scenes/characters/enemies/projectile.tscn")

func _ready():
	hit_box.enable_hitbox()
	ray_cast.enabled = true
	ray_cast.collision_mask = 1
	
	shoot_timer.connect("timeout", Callable(self, "_on_shoot_timer_timeout"))
	shoot_timer.set_one_shot(true)
	shoot_timer.set_wait_time(shoot_interval)

func _physics_process(delta):
	if is_dead:
		return
	
	if player and is_instance_valid(player) and can_see_player():
		if global_position.distance_to(player.global_position) <= shooting_range:
			velocity = Vector2.ZERO  # Ensure not moving while shooting
			shoot_at_player()
		pause_time = 0
	elif pause_time < pause_duration:
		pause(delta)
	else:
		wander(delta)
	
	move_and_slide()

func snap_animation_sprite(animation: String, direction: Vector2 = Vector2.ZERO) -> void:
	if direction == Vector2.ZERO:
		direction = velocity

	# Calulate snapping index (0-7)
	var index = int(round(direction.angle() / (PI / 4))) % 8

	# Handle negative angles
	if index < 0:
		index += 8

	if index % 2 == 0:
		animated_sprite_2d.play(animation)
		animated_sprite_2d.rotation = index * PI / 4
	else:
		animated_sprite_2d.play(animation + "_diag")
		animated_sprite_2d.rotation = index * PI / 4 + (PI / 4)


func can_see_player() -> bool:
	if not player or not is_instance_valid(player):
		return false
	
	# Reset the ray_cast position and check for collisions
	ray_cast.global_position = global_position
	ray_cast.target_position = player.global_position - global_position
	ray_cast.force_raycast_update()
	
	# Ensure the ray doesn't hit walls (or obstacles) before detecting the player
	return not ray_cast.is_colliding()

func shoot_at_player():
	var direction = (player.global_position - global_position).normalized()
	snap_animation_sprite("shoot", direction)
	
	if can_shoot and player and is_instance_valid(player):
		can_shoot = false
		shoot_timer.start()
		
		# Calculate the direction to the player
		
		var projectile = Projectile.instantiate()
		# idk why i need to move up y -24, maybe starts at corner of bug or something
		projectile.global_position = global_position + Vector2(0, -24) 
		projectile.set_velocity(direction * projectile_speed)
		
		# Add projectile to scene and play shooting animation
		get_parent().add_child(projectile)

func _on_shoot_timer_timeout():
	can_shoot = true

func pause(delta):
	pause_time += delta
	velocity = Vector2.ZERO

func wander(delta):
	wander_time += delta
	if wander_time >= wander_interval:
		wander_time = 0
		wander_target = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	
	if global_position.distance_to(wander_target) > 5:
		velocity = (wander_target - global_position).normalized() * wander_speed
	else:
		velocity = Vector2.ZERO
	
	snap_animation_sprite("walk")


func _on_detection_area_body_entered(body):
	if body and body.name == "player":
		player = body
		player_chase = true
		# Reset pause time when the player is detected
		pause_time = 0

func _on_detection_area_body_exited(body):
	if body and body.name == "player":
		player = null
		player_chase = false
		# Optional: Reset pause time or wander logic if needed
		pause_time = 0

func take_damage(amount: int, attacker_position: Vector2):
	if is_dead:
		return
	
	current_health -= amount
	
	if current_health <= 0:
		die()


func die():
	is_dead = true
	animated_sprite_2d.play("death")
	audio_death.play()
	await animated_sprite_2d.animation_finished
	queue_free()
