extends CanvasLayer

@onready var score_label: Label = $score_label
@onready var timer_label: Label = $timer_label
@onready var star_time_label: Label = $star_time_label
@onready var fish_icon: Sprite2D = $anchor_control/fish_icon
@onready var heart_1: Sprite2D = $anchor_control/heart_1
@onready var heart_2: Sprite2D = $anchor_control/heart_2
@onready var heart_3: Sprite2D = $anchor_control/heart_3
@onready var star_1: Sprite2D = $anchor_star/star_1
@onready var star_2: Sprite2D = $anchor_star/star_2
@onready var star_3: Sprite2D = $anchor_star/star_3

var heart_filled: Texture2D = preload("res://assets/heart/heart-filled.png")
var heart_empty: Texture2D = preload("res://assets/heart/heart-empty.png")

var star_filled: Texture2D = preload("res://assets/testlevel/star-hud-filled.png")
var star_empty: Texture2D = preload("res://assets/testlevel/star-hud-empty.png")

func update_timer(time_passed: float, level_star_time: int) -> void:
	var minutes = int(time_passed / 60)
	var seconds = int(time_passed) % 60
	var milliseconds = int((time_passed - int(time_passed)) * 100)
	
	# Format the text as MM:SS.MS
	timer_label.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
	
	# Convert level star time to MM:SS format
	var star_minutes = int(level_star_time / 60)
	var star_seconds = level_star_time % 60
	star_time_label.text = "%02d:%02d" % [star_minutes, star_seconds]

# Reusable function to update a UI sprite's texture and bounce if needed.
func update_ui_sprite(sprite: Sprite2D, isActive: bool, filledTexture, emptyTexture, bounce: bool = false) -> void:
	var targetTexture = filledTexture if isActive else emptyTexture
	# Only update and bounce if the texture is changing.
	if sprite.texture != targetTexture:
		sprite.texture = targetTexture
		if bounce:
			bounce_sprite(sprite)

func update_stars(stars_earned: int) -> void:
	var stars = [star_3, star_2, star_1]
	for i in range(stars.size()):
		# Set sprite to filled if within stars_earned,
		# otherwise set to empty and bounce if it was changed.
		update_ui_sprite(stars[i], i < stars_earned, star_filled, star_empty, i >= stars_earned)

func update_health(new_health) -> void:
	var 	hearts = [heart_3, heart_2, heart_1]
	for i in range(hearts.size()):
		var isFilled = i < new_health
		# Bounce the sprite if it is the one that just changed state:
		# For a filled heart, bounce the last one gained;
		# for an empty heart, bounce the first one lost.
		var bounce = false
		if isFilled and i == new_health - 1:
			bounce = true
		elif not isFilled and i == new_health:
			bounce = true
		update_ui_sprite(hearts[i], isFilled, heart_filled, heart_empty, bounce)

func bounce_sprite(sprite: Sprite2D) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "scale", Vector2(3.0, 3.0), 0.15).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.15).set_trans(Tween.TRANS_BOUNCE)

func update_score(score, max_score) -> void:
	score_label.text = str(score) + "/" + str(max_score) + " Cheese"

func update_fish_icon(has_fish: bool) -> void:
	if has_fish:
		fish_icon.visible = true
	else:
		fish_icon.visible = false
