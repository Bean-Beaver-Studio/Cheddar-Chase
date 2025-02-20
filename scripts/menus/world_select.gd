extends Control

@onready var worlds: Array = [$world_icon1, $world_icon2, $world_icon3, $world_icon4, $world_icon5]
@onready var main_menu_scene = load("res://scenes/menus/main_menu.tscn")
@onready var animation_player: AnimationPlayer = $clouds/animation_player
var current_world: int = 0
var move_tween: Tween

func _ready() -> void:
	# Update all world states
	for world in worlds:
		world.update_world_state()
	
	$player_icon.global_position = worlds[current_world].global_position
	#animation_player.play("cloud")

func _input(event: InputEvent) -> void:
	if move_tween and move_tween.is_running():
		return
	
	if event.is_action_pressed("ui_left") and current_world > 0 and not worlds[current_world - 1].is_locked:
		current_world -= 1
		tween_icon()
	
	if event.is_action_pressed("ui_right") and current_world < worlds.size() - 1 and not worlds[current_world + 1].is_locked:
		current_world += 1
		tween_icon()
	
	if event.is_action_pressed("ui_accept"):
		if worlds[current_world].level_select_packed and not worlds[current_world].is_locked:
			game_data.set_current_world(current_world)
			game_data.set_level_select_scene(worlds[current_world].level_select_packed)
			get_tree().change_scene_to_packed(worlds[current_world].level_select_packed)
	
	if event.is_action_pressed("ui_cancel"):
		if main_menu_scene:
			get_tree().change_scene_to_packed(main_menu_scene)
		else:
			print("Failed to load main menu")

func tween_icon():
	move_tween = get_tree().create_tween()
	move_tween.tween_property($player_icon, "global_position", worlds[current_world].global_position, 0.5).set_trans(Tween.TRANS_SINE)
