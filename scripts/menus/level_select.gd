extends Control
class_name LevelSelect

@onready var current_level: LevelIcon = $level_icon1
#@onready var animation_player: AnimationPlayer = $clouds/animation_player
@onready var world_select_scene = load("res://scenes/menus/world_select.tscn")
var move_tween: Tween

func _ready() -> void:
	# Find the correct level icon to spawn on
	var target_level_name = game_data.get_current_level_icon_name()
	for level in get_tree().get_nodes_in_group("level_icons"):
		level = level as LevelIcon
		if level:
			level.mouse_entered.connect(_level_hover.bind(level))
			level.pressed.connect(enter_level.bind(level))
			if level.level_name == target_level_name:
				current_level = level
	
	$player_icon.global_position = current_level.global_position
	#animation_player.play("cloud")

func _level_hover(level: LevelIcon):
	select_level(level)

func _input(event: InputEvent) -> void:
	if move_tween and move_tween.is_running():
		return
		
	if event.is_action_pressed("ui_left") and current_level.next_level_left and not current_level.next_level_left.is_locked:
		select_level(current_level.next_level_left)
	
	if event.is_action_pressed("ui_right") and current_level.next_level_right and not current_level.next_level_right.is_locked:
		select_level(current_level.next_level_right)
	
	if event.is_action_pressed("ui_up") and current_level.next_level_up and not current_level.next_level_up.is_locked:
		select_level(current_level.next_level_up)
	
	if event.is_action_pressed("ui_down"):
		select_level(current_level.next_level_down)
	
	if event.is_action_pressed("ui_cancel"):
		game_data.reset_level_select_scene()
		get_tree().change_scene_to_packed(world_select_scene)
	
	if event.is_action_pressed("ui_accept"):
		enter_level(current_level)

func select_level(level: LevelIcon):
	if level and not level.is_locked:
		current_level = level
		tween_icon()

func enter_level(level: LevelIcon):
	if not level.is_locked and level.next_scene_path:
		game_data.set_current_level(level.next_scene_path)
		functions.load_screen_to_scene(level.next_scene_path)

func tween_icon():
	move_tween = get_tree().create_tween()
	move_tween.tween_property($player_icon, "global_position", current_level.global_position, 0.1).set_trans(Tween.TRANS_SINE)
	# Update the current level in game_data when moving
	game_data.current_level_icon_name = current_level.level_name
