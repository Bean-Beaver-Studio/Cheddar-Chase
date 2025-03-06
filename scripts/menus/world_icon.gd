@tool
extends Control
class_name WorldButton

@export var world_index: int = 1
@export var level_select_packed: PackedScene = load("res://scenes/menus/level_select_world_1.tscn")
@onready var level_select_scene: LevelSelect = level_select_packed.instantiate()
var is_locked: bool = true

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("world_icons")
		update_world_state()
	$label.text = "World " + str(world_index)
	$shadow.text = "World " + str(world_index)

func update_world_state() -> void:
	var progress_data = save_manager.load_progress()
	var highest_level = progress_data["highest_level"]
	
	var specific_requirements = {
	2: 7,  # World 2 unlocks after level 3
	3: 14,  # World 3 unlocks after level 7
	4: 21, # World 4 unlocks after level 12
	5: 28  # World 5 unlocks after level 18
	}
	
	is_locked = highest_level <= specific_requirements.get(world_index, 0)
	
	if is_locked:
		$texture_rect.modulate = Color(0.5, 0.5, 0.5)  # Gray out if locked
	else:
		$texture_rect.modulate = Color(1, 1, 1)  # Normal color if unlocked

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		$label.text = "World " + str(world_index)
