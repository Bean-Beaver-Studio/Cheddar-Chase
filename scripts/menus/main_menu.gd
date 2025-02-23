extends CanvasLayer

const level_select = preload("res://scenes/menus/world_select.tscn") as PackedScene

const SAVE_FILE_PATH = "user://volume_data.json"

func _ready() -> void:
	load_volumes()


func _on_start_button_pressed() -> void:
	if level_select:
		get_tree().change_scene_to_packed(level_select)
	else:
		print("Failed to load main menu")


func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/options_menu.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func load_volumes() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var json = JSON.parse_string(json_string)
			
			if json:
				# Load and apply volumes
				var master_volume = json.get("master_volume", 1.0)
				var music_volume = json.get("music_volume", 1.0)
				var sfx_volume = json.get("sfx_volume", 1.0)
				
				# Apply loaded volumes to audio buses
				var master_index = AudioServer.get_bus_index("Master")
				var music_index = AudioServer.get_bus_index("Music")
				var sfx_index = AudioServer.get_bus_index("SFX")
				
				AudioServer.set_bus_volume_db(master_index, linear_to_db(master_volume))
				AudioServer.set_bus_volume_db(music_index, linear_to_db(music_volume))
				AudioServer.set_bus_volume_db(sfx_index, linear_to_db(sfx_volume))
