extends CharacterBody2D

# Variables for movement
var speed = 100
var roll_speed = 210
var roll_duration = 0.5
var is_rolling = false
var roll_timer = 0.0
var is_attacking = false
var attack_duration = 0.5  
var is_falling = false
var is_flying = false
var attack_switch = false
var is_invincible = false
var player_direction = Vector2.RIGHT

# Cooldown variables
var attack_cooldown = 0.7 
var attack_timer = 0.0 

# Spawn
var spawn_point: Vector2

# Variables for Health
var max_health = 3
var current_health = max_health
var is_dead = false
signal trigger_death_menu
signal player_take_damage

# Knockback variables
var knockback_velocity = Vector2.ZERO
var knockback_duration = 0.2
var knockback_timer = 0.0
var knockback_strength = 220

# Audio references
@onready var audio_walk: AudioStreamPlayer2D = $audio/audio_walk
@onready var audio_fall: AudioStreamPlayer2D = $audio/audio_fall
@onready var audio_attack_left: AudioStreamPlayer2D = $audio/audio_attack_left
@onready var audio_attack_right: AudioStreamPlayer2D = $audio/audio_attack_right
@onready var audio_damaged: AudioStreamPlayer2D = $audio/audio_damaged
@onready var audio_rolling: AudioStreamPlayer2D = $audio/audio_rolling
@onready var audio_eaten: AudioStreamPlayer2D = $audio/audio_eaten
@onready var audio_heart: AudioStreamPlayer2D = $audio/audio_heart

# References to nodes
@onready var hud: CanvasLayer = $hud
@onready var animated_sprite_2d: AnimatedSprite2D = $animated_sprite_mouse
@onready var hit_box: HitBox = $hit_box
@onready var hurt_box: HurtBox = $hurt_box
@onready var invincibility_timer: Timer = %invincibility_timer

func _ready():
	spawn_point = global_position
	animated_sprite_2d.connect("animation_finished", Callable(self, "_on_animation_finished"))
	hurt_box.connect("body_entered", Callable(self, "_on_hurtbox_body_entered"))
	hit_box.disable_hitbox()  # Ensure hitbox is disabled initially
	hurt_box.enable_hurtbox()  # Ensure hurtbox is enabled initially
	hud.update_health(current_health) # Initialize health in HUD

func _process(delta):
	if is_dead:
		return
	
	# Update attack cooldown timer
	if attack_timer > 0:
		attack_timer -= delta
	
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 5 * delta)
	else:
		handle_movement_and_actions(delta)
	
	move_and_slide()

# Function to handle the movement and actions
func handle_movement_and_actions(delta):
	# Rolling logic
	if is_rolling:
		roll_timer -= delta
		
		if roll_timer <= 0:
			is_rolling = false
			animated_sprite_2d.play("walk")
			hurt_box.enable_hurtbox()
		else:
			velocity = velocity.normalized() * lerp(roll_speed, 0, 1 - (roll_timer / roll_duration))
	
	# Attacking logic
	elif is_attacking:
		
		if is_falling:
			velocity = Vector2.ZERO  # Prevent movement while falling
			return  # Exit the function if falling
		
		if !animated_sprite_2d.is_playing():
			is_attacking = false
			
			if !is_rolling:
				animated_sprite_2d.play("idle")
			velocity = Vector2.ZERO
		else:
			var input_vector = Vector2.ZERO
			if Input.is_action_pressed("ui_right"):
				input_vector.x += 1
			if Input.is_action_pressed("ui_left"):
				input_vector.x -= 1
			if Input.is_action_pressed("ui_down"):
				input_vector.y += 1
			if Input.is_action_pressed("ui_up"):
				input_vector.y -= 1
	
			if input_vector.length() > 0:
				player_direction = input_vector.normalized()
				velocity = player_direction * speed
				animated_sprite_2d.rotation = velocity.angle()
			else:
				velocity = Vector2.ZERO
	
	else:
		# Handle normal movement input if not rolling or attacking
		if is_falling:
			velocity = Vector2.ZERO  # Prevent movement while falling
			return  # Exit the function if falling
		
		var input_vector = Vector2.ZERO
		if Input.is_action_pressed("ui_right"):
			input_vector.x += 1
		if Input.is_action_pressed("ui_left"):
			input_vector.x -= 1
		if Input.is_action_pressed("ui_down"):
			input_vector.y += 1
		if Input.is_action_pressed("ui_up"):
			input_vector.y -= 1

		if input_vector.length() > 0:
			player_direction = input_vector.normalized()
			velocity = player_direction * speed
			
			if !is_colliding():
				animated_sprite_2d.play("walk")
				if !audio_walk.playing:
					audio_walk.play()
			animated_sprite_2d.rotation = velocity.angle()
		else:
			velocity = Vector2.ZERO
			audio_walk.stop()
			
			if !is_attacking and !is_rolling:
				animated_sprite_2d.play("idle")
	
		# Roll mechanic: Only allow rolling if there is movement input and the roll action is just pressed
		if Input.is_action_just_pressed("ui_jump") and input_vector.length() > 0:
			is_rolling = true
			roll_timer = roll_duration
			velocity = velocity.normalized() * roll_speed
			animated_sprite_2d.play("roll")
			audio_rolling.play()
			hurt_box.disable_hurtbox()
	
	# Play attack animation if attack button is pressed and not rolling, not falling, and cooldown has passed
	if Input.is_action_just_pressed("ui_attack") and !is_rolling and !is_falling and attack_timer <= 0:
		is_attacking = true
		attack_timer = attack_cooldown  # Reset the cooldown timer
		
		if attack_switch:
			animated_sprite_2d.play("attack_right")
			audio_attack_right.play()
			attack_switch = false
		else:
			animated_sprite_2d.play("attack_left")
			audio_attack_left.play()
			attack_switch = true
		
		hit_box.enable_hitbox()
		hurt_box.disable_hurtbox()
	
	# Play obstruct animation if there is a collision and not rolling
	if is_colliding() and !is_rolling and !is_attacking and !is_falling:
		animated_sprite_2d.play("obstruct")

# Function to check for collision
func is_colliding() -> bool:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision:
			var collision_normal = collision.get_normal()
			if collision_normal.dot(player_direction) < -0.9:
				# only play collision animation if player is walking directly towards a wall
				return true
	return false


# Function to handle taking damage
func take_damage(amount: int, attacker_position: Vector2):
	if is_dead or is_invincible:
		return
	
	# Update health
	current_health -= amount
	hud.update_health(current_health)

	start_invincibility()
	
	# Emit signal when damage is taken
	player_take_damage.emit()
	
	# Calculate knockback direction here
	var direction = (position - attacker_position).normalized()
	knockback_velocity = direction * knockback_strength
	knockback_timer = knockback_duration
	animated_sprite_2d.play("damaged")
	audio_damaged.play()
	
	if current_health <= 0:
		die()

func start_invincibility() -> void:
	is_invincible = true
	
	var tween = create_tween()
	tween.set_loops(4) # Flash 4 times
	tween.tween_property(animated_sprite_2d, "modulate:a", 0.2, 0.1)
	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.1)
	
	invincibility_timer.start(1.0)

# Function to handle player death
func die():	
	is_dead = true
	animated_sprite_2d.play("death")
	Engine.time_scale = 0.5
	trigger_death_menu.emit()

# Function to check if hurtbox is entered
func _on_hurtbox_body_entered(body):
	if body is HitBox:
		var attacker_position = body.global_position
		take_damage(1, attacker_position)

# Function to handle when animation is finished
func _on_animation_finished() -> void:
	if is_rolling:
		is_rolling = false
		animated_sprite_2d.play("walk")  
	elif is_attacking:
		is_attacking = false
		hit_box.disable_hitbox()
		hurt_box.enable_hurtbox()
		
		if !is_rolling:
			animated_sprite_2d.play("idle")
		velocity = Vector2.ZERO

# Function to handle when the player falls into a pit
func fall_in_pit():
	if is_falling:
		return
	is_falling = true
	
	animated_sprite_2d.play("fall")
	audio_fall.play()
	
	current_health = 0
	hud.update_health(current_health)
	trigger_death_menu.emit()
	
	var tween = get_tree().create_tween()
	tween.tween_property($animated_sprite_mouse, "scale", Vector2(), 1)
	tween.parallel().tween_property($animated_sprite_mouse, "modulate", Color.BLACK, 0.5)
	tween.parallel().tween_property($animated_sprite_mouse, "rotation_degrees", 360.0, 2)
	await tween.finished
	
	is_falling = false

func play_cheese_sound() -> void:
	audio_eaten.play()

func play_heart_sound() -> void:
	audio_heart.play()

func _on_invincibility_timer_timeout() -> void:
	is_invincible = false
