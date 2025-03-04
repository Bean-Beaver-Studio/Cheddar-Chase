extends Control

@onready var worlds: Array = $HFlowContainer.get_children()
@onready var main_menu_scene = load("res://scenes/menus/main_menu.tscn")
#@onready var animation_player: AnimationPlayer = $clouds/animation_player
var current_world: int = 0
var move_tween: Tween

func _ready() -> void:
	# Update all world states
	for i in range(worlds.size()):
		var world = worlds[i] as WorldButton
		if world:
			world.update_world_state()
			world.mouse_entered.connect(set_current_world.bind(i))
			world.pressed.connect(enter_world.bind(i))
	await get_tree().process_frame
	set_current_world(0)
	#animation_player.play("cloud")


func set_current_world(id : int):
	if not worlds[id].is_locked:
		current_world = id
		tween_icon()

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
		enter_world(current_world)
	
	if event.is_action_pressed("ui_cancel"):
		if main_menu_scene:
			get_tree().change_scene_to_packed(main_menu_scene)
		else:
			print("Failed to load main menu")

func enter_world(world_id : int):
	print("Hello")
	if worlds[world_id].level_select_packed and not worlds[world_id].is_locked:
			game_data.set_current_world(world_id)
			game_data.set_level_select_scene(worlds[world_id].level_select_packed)
			get_tree().change_scene_to_packed(worlds[world_id].level_select_packed)

func tween_icon():
	move_tween = get_tree().create_tween()
	move_tween.tween_property(%player_icon, "global_position", worlds[current_world].global_position + Vector2(8, 18), 0.1).set_trans(Tween.TRANS_SINE)
