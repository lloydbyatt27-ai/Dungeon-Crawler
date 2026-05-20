extends Control
## Title screen. New Game / Continue (if save exists) / Quit.

@onready var new_game_button: Button = $Center/VBox/NewGameButton
@onready var continue_button: Button = $Center/VBox/ContinueButton
@onready var quit_button: Button = $Center/VBox/QuitButton
@onready var save_info_label: Label = $Center/VBox/SaveInfo

const DUNGEON_PATH: String = "res://scenes/world/TestDungeon.tscn"


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	quit_button.pressed.connect(_on_quit)
	_refresh_save_state()


func _refresh_save_state() -> void:
	var has_save := SaveSystem.has_save()
	continue_button.disabled = not has_save
	save_info_label.visible = has_save
	if has_save:
		save_info_label.text = "Saved character detected."


func _on_new_game() -> void:
	SaveSystem.delete_save()
	SaveSystem.pending_load_data = {}
	# Reset GameState run stats so the area complete screen shows fresh numbers
	GameState.run_stats = {
		"monsters_killed": 0,
		"bosses_defeated": 0,
		"deaths": 0,
		"gold_earned_total": 0,
		"items_collected": 0,
		"play_time_seconds": 0.0,
		"dungeons_completed": 0,
	}
	get_tree().change_scene_to_file(DUNGEON_PATH)


func _on_continue() -> void:
	if SaveSystem.has_save():
		SaveSystem.load_save()
	get_tree().change_scene_to_file(DUNGEON_PATH)


func _on_quit() -> void:
	get_tree().quit()
