extends Button
class_name LevelIcon

@export var level_name: String = "1"
@onready var star_empty = load("res://assets/menus/icons/star_empty.png")
@onready var star_filled = load("res://assets/menus/icons/star_filled.png")
@onready var level_icon_completed = load("res://assets/menus/icons/level_icon_completed.png")
@onready var level_icon_allstar = load("res://assets/menus/icons/level_icon_allstar.png")
@onready var level_icon = load("res://assets/menus/icons/level_icon.png")
@onready var label: Label = $background/label
@export_file("*.tscn") var next_scene_path: String
@export var next_level_up: LevelIcon
@export var next_level_down: LevelIcon
@export var next_level_left: LevelIcon
@export var next_level_right: LevelIcon
var is_locked: bool = true

func _ready() -> void:
	add_to_group("level_icons")
	if not Engine.is_editor_hint():
		update_level_state()
	label.text = "Level " + str(level_name)

func update_level_state() -> void:
	var save_data = save_manager.load_progress()
	var highest_level = save_data["highest_level"]
	var level_stars = save_data["level_stars"]
	
	# Convert level_name to integer for proper comparison
	var this_level_number = int(level_name)
	
	# A level is unlocked if its number is less than or equal to the highest_level
	is_locked = this_level_number > highest_level
	
	if is_locked:
		modulate_level(Color(0.2, 0.2, 0.2))
		$star_1.texture = star_empty
		$star_2.texture = star_empty
		$star_3.texture = star_empty
	else:
		modulate_level(Color(1, 1, 1))
		var stars = level_stars.get(level_name, 0)  # Default to 0 stars if missing
		$star_1.texture = star_filled if stars >= 1 else star_empty
		$star_2.texture = star_filled if stars >= 2 else star_empty
		$star_3.texture = star_filled if stars >= 3 else star_empty
		
		# Set level icon textures
		if stars >= 3:
			$level_icon.texture = level_icon_allstar
		elif stars >= 1:
			$level_icon.texture = level_icon_completed

func modulate_level(color: Color) -> void:
	$level_icon.modulate = color
	#$label.modulate = color

func display_stars(star_count: int) -> void:
	var star_nodes = [$star_1, $star_2, $star_3]
	for i in range(3):
		if i < star_count:
			star_nodes[i].modulate = Color(1, 1, 1)
		else:
			star_nodes[i].modulate = Color(0.2, 0.2, 0.2)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		$label.text = "Level " + str(level_name)
