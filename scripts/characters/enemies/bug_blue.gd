extends CharacterBody2D

# Variables for movement
var speed = 25
var chase_speed = 30
var wander_speed = 10
var player_chase = false
var player = null
var wander_target = Vector2.ZERO
var wander_time = 0
var wander_interval = 3
var pause_time = 0
var pause_duration = 3
var is_rolling = false
var is_falling = false
var is_flying = false

# Variables for Health
var max_health = 5
var current_health = 5
var is_dead = false

# Variables for Knockback
var knockback_velocity = Vector2.ZERO
var knockback_duration = 0.2
var knockback_timer = 0.0
var knockback_strength = 120

# Audio references
@onready var audio_damaged: AudioStreamPlayer2D = $audio/audio_damaged
@onready var audio_death: AudioStreamPlayer2D = $audio/audio_death

# References to nodes
@onready var animated_sprite_2d: AnimatedSprite2D = $animated_sprite_bug_blue
@onready var ray_cast: RayCast2D = $detection_ray
@onready var detection_area: Area2D = $detection_area
@onready var hit_box: HitBox = $hit_box


func _ready():
	hit_box.enable_hitbox()
	
	if not ray_cast:
		ray_cast = RayCast2D.new()
		add_child(ray_cast)
	
	ray_cast.enabled = true
	ray_cast.collision_mask = 1 # Ensure this is set to the layer of the player

func _physics_process(delta):
	if is_dead:
		return
	
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
	else:
		if player and is_instance_valid(player) and can_see_player():
			chase_player()
			pause_time = 0
		elif pause_time < pause_duration:
			pause(delta)
		else:
			wander(delta)
	
	snap_animation_sprite()
	move_and_slide()
	

func snap_animation_sprite() -> void:
	if velocity == Vector2.ZERO and knockback_velocity == Vector2.ZERO:
		return

	# Calulate snapping index (0-7)
	var index = int(round(velocity.angle() / (PI / 4))) % 8

	# Handle negative angles
	if index < 0:
		index += 8

	if index % 2 == 0:
		animated_sprite_2d.play("walk")
		animated_sprite_2d.rotation = index * PI / 4
	else:
		animated_sprite_2d.play("walk_diag")
		animated_sprite_2d.rotation = index * PI / 4 + (PI / 4)

func can_see_player() -> bool:
	if not player or not is_instance_valid(player):
		return false
	
	ray_cast.global_position = global_position
	ray_cast.target_position = player.global_position - global_position
	ray_cast.force_raycast_update()
	
	return not ray_cast.is_colliding()

func chase_player():
	if not player or not is_instance_valid(player):
		return
	
	if is_falling:
		velocity = Vector2.ZERO
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed

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

func _on_detection_area_body_entered(body):
	if body and body.name == "player":
		player = body
		player_chase = true

func _on_detection_area_body_exited(body):
	if body and body.name == "player":
		player = null
		player_chase = false
		pause_time = 0

func take_damage(amount: int, attacker_position: Vector2):
	if is_dead:
		return
	
	current_health -= amount
	
	if current_health <= 0:
		die()
	else:
		var direction = (global_position - attacker_position).normalized()
		knockback_velocity = direction * knockback_strength
		knockback_timer = knockback_duration
		
		var tween = create_tween()
		tween.tween_property(self, "modulate:v", 1, 0.25).from(1000)
	
func die():
	is_dead = true
	animated_sprite_2d.play("death")
	audio_death.play()
	await animated_sprite_2d.animation_finished
	queue_free()

func fall_in_pit():
	if is_falling:
		return
	is_falling = true
	
	hit_box.call_deferred("disable_hitbox")
	
	# Create a new Tween instance
	var tween = get_tree().create_tween()
	
	tween.tween_property($animated_sprite_bug_blue, "scale", Vector2(), 1)
	tween.parallel().tween_property($animated_sprite_bug_blue, "modulate", Color.BLACK, 0.5)
	tween.parallel().tween_property($animated_sprite_bug_blue, "rotation_degrees", 360.0, 2)
	await tween.finished
	
	queue_free()
