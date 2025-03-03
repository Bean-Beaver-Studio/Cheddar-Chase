extends CanvasLayer

@onready var window: ColorRect = $window
@onready var return_button: Button = $window/return_button
@onready var win_label: Label = $window/win_label
@onready var background: TextureRect = $background
@onready var star_1: Sprite2D = %star_1
@onready var star_2: Sprite2D = %star_2
@onready var star_3: Sprite2D = %star_3
@onready var time_label: Label = %time_label

var empty_star_tex = preload("res://assets/menus/icons/star_empty.png")

@export var fade_in_time = 0.2 

func _ready() -> void:
	var opacity = 0

	background.modulate.a = opacity
	return_button.modulate.a = opacity
	win_label.modulate.a = opacity
	
	self.visible = false

func fade_in(time: float, star_time: int):
	# Ensure the win screen continues to process while the game is paused
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	
	get_tree().paused = true
	
	self.visible = true
	
	# Format the time as MM:SS.MS
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	
	# Convert star time to MM:SS format
	var star_minutes = star_time / 60
	var star_seconds = star_time % 60
	
	time_label.text = "Time: %02d:%02d.%02d / %02d:%02d" % [minutes, seconds, milliseconds, star_minutes, star_seconds]
		
	var opacity = 1.0
	
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", opacity, fade_in_time)
	tween.parallel().tween_property(win_label, "modulate:a", opacity, fade_in_time)
	tween.parallel().tween_property(return_button, "modulate:a", opacity, fade_in_time)

func _on_return_button_pressed() -> void:
	# Unpause the game when pressing the button
	get_tree().paused = false

	var level_select = game_data.get_level_select_scene()
	if level_select:
		var music = load("res://assets/music/Cheese_on_the_moon.wav")
		music_manager.change_music(music)
		game_data.transition_to_level_select(game_data.get_current_world(), level_select)
	else:
		print("Failed to load level select menu")

func update_stars(damage_taken: bool, time: float, star_time: int) -> void:
	if damage_taken:
		star_2.texture = empty_star_tex
	
	if  time > star_time:
		star_3.texture = empty_star_tex
