extends CanvasLayer

@onready var menu: TextureRect = %background
@onready var you_sure_screen: ColorRect = %you_sure_screen
@onready var data_deleted_screen: ColorRect = %data_deleted_screen
@onready var master_volume_slider: HSlider = %master_volume_slider
@onready var music_volume_slider: HSlider = %music_volume_slider
@onready var sfx_volume_slider: HSlider = %sfx_volume_slider

func _ready() -> void:
	you_sure_screen.visible = false
	data_deleted_screen.visible = false
	
	master_volume_slider.value = get_master_volume()
	music_volume_slider.value = get_music_volume()
	sfx_volume_slider.value = get_sfx_volume()

func _on_reset_progress_button_pressed() -> void:
	menu.visible = false
	you_sure_screen.visible = true
	you_sure_screen.find_children("*_button")[0].grab_focus()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

func _on_yes_button_pressed() -> void:
	save_manager.delete_save()
	save_manager.initialize_save()
	game_data.current_level_icon_name = "1"
	
	you_sure_screen.visible = false
	data_deleted_screen.visible = true
	data_deleted_screen.find_children("*_button")[0].grab_focus()

func _on_no_button_pressed() -> void:
	back_to_menu()

func _on_ok_button_pressed() -> void:
	back_to_menu()

func back_to_menu() -> void:
	data_deleted_screen.visible = false
	you_sure_screen.visible = false
	menu.visible = true
	master_volume_slider.grab_focus()

func _on_check_box_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_check_box_integer_toggled(toggled_on: bool) -> void:
	var win = get_window()
	if toggled_on:
		win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	else:
		win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL

# ---------- AUDIO ----------

const SAVE_FILE_PATH = "user://volume_data.json"

func _on_master_volume_slider_value_changed(value: float) -> void:
	var index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(index, linear_to_db(value))
	save_volumes(value, get_music_volume(), get_sfx_volume())

func _on_music_volume_slider_value_changed(value: float) -> void:
	var index = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(index, linear_to_db(value))
	save_volumes(get_master_volume(), value, get_sfx_volume())

func _on_sfx_volume_slider_value_changed(value: float) -> void:
	var index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(index, linear_to_db(value))
	save_volumes(get_master_volume(), get_music_volume(), value)

# Helper functions to get current volumes
func get_master_volume() -> float:
	var index = AudioServer.get_bus_index("Master")
	return db_to_linear(AudioServer.get_bus_volume_db(index))

func get_music_volume() -> float:
	var index = AudioServer.get_bus_index("Music")
	return db_to_linear(AudioServer.get_bus_volume_db(index))

func get_sfx_volume() -> float:
	var index = AudioServer.get_bus_index("SFX")
	return db_to_linear(AudioServer.get_bus_volume_db(index))

func save_volumes(master: float, music: float, sfx: float) -> void:
	# First load existing data
	var save_data = {}
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var json = JSON.parse_string(json_string)
			if json:
				save_data = json
	
	# Update only the volume data
	save_data["master_volume"] = master
	save_data["music_volume"] = music
	save_data["sfx_volume"] = sfx
	
	# Save everything back to file
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
