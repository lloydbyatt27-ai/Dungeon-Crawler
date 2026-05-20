extends CanvasLayer
## Triggers on boss_defeated. After a 2s delay, shows a summary modal with
## the run's deltas (kills, gold, items, time), saves the player, and offers
## a "Return to Hub" button that goes back to the MainMenu.

@onready var root: Control = $Root
@onready var title_label: Label = $Root/Panel/Margin/VBox/Title
@onready var kills_label: Label = $Root/Panel/Margin/VBox/Grid/KillsValue
@onready var gold_label: Label = $Root/Panel/Margin/VBox/Grid/GoldValue
@onready var items_label: Label = $Root/Panel/Margin/VBox/Grid/ItemsValue
@onready var time_label: Label = $Root/Panel/Margin/VBox/Grid/TimeValue
@onready var continue_button: Button = $Root/Panel/Margin/VBox/ContinueButton

const MAIN_MENU_PATH: String = "res://scenes/ui/MainMenu.tscn"


func _ready() -> void:
	root.visible = false
	EventBus.boss_defeated.connect(_on_boss_defeated)
	continue_button.pressed.connect(_on_continue_pressed)


func _on_boss_defeated(_boss: Node) -> void:
	# Let the death animation play for a moment, then reveal.
	await get_tree().create_timer(2.0).timeout
	_show()


func _show() -> void:
	root.visible = true
	# Pull deltas from GameState
	kills_label.text = "%d" % int(GameState.run_delta("monsters_killed"))
	gold_label.text = "+%d" % int(GameState.run_delta("gold_earned_total"))
	items_label.text = "%d" % int(GameState.run_delta("items_collected"))
	var seconds: float = GameState.run_delta("play_time_seconds")
	time_label.text = "%d:%02d" % [int(seconds / 60.0), int(seconds) % 60]

	# Save the player
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		SaveSystem.save_player(players[0])

	# Bump dungeons_completed
	GameState.run_stats.dungeons_completed += 1

	# Fade-in
	root.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.6)


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
