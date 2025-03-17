extends CanvasLayer

@onready var cheese_on_the_moon = load("res://assets/music/Cheese_on_the_moon.wav")
var is_paused: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS # Make sure we can process this scene when paused

func toggle() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused  # Pause the game
	visible = is_paused   # Show/hide the pause menu

func _on_resume_button_pressed() -> void:
	toggle()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false  # Unpause the game first
	get_tree().reload_current_scene()  # Restart the current scene

func _on_menu_button_pressed() -> void:
	get_tree().paused = false  # Unpause before changing scenes
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	music_manager.change_music(cheese_on_the_moon)
