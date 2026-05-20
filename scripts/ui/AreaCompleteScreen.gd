extends CanvasLayer
## Triggers on boss_defeated. Shows a summary modal with run deltas, saves
## the player. In normal mode the button returns to HubTown. In endless mode
## the same button descends to the next floor (re-generates the dungeon).

@onready var root: Control = $Root
@onready var title_label: Label = $Root/Panel/Margin/VBox/Title
@onready var kills_label: Label = $Root/Panel/Margin/VBox/Grid/KillsValue
@onready var gold_label: Label = $Root/Panel/Margin/VBox/Grid/GoldValue
@onready var items_label: Label = $Root/Panel/Margin/VBox/Grid/ItemsValue
@onready var time_label: Label = $Root/Panel/Margin/VBox/Grid/TimeValue
@onready var continue_button: Button = $Root/Panel/Margin/VBox/ContinueButton

const HUB_PATH: String = "res://scenes/world/HubTown.tscn"
const DUNGEON_PATH: String = "res://scenes/world/ProceduralDungeon.tscn"


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

	# Endless vs normal flow
	var players := get_tree().get_nodes_in_group("player")
	if SaveSystem.endless_mode:
		title_label.text = "FLOOR %d CLEARED" % SaveSystem.current_endless_floor
		continue_button.text = "Descend to Floor %d" % (SaveSystem.current_endless_floor + 1)
		# Update the player's best record
		if not players.is_empty():
			var stats: CharacterStats = players[0].stats
			if stats and SaveSystem.current_endless_floor > stats.best_endless_floor:
				stats.best_endless_floor = SaveSystem.current_endless_floor
	else:
		title_label.text = "AREA COMPLETE"
		continue_button.text = "Return to Hub"
		# Unlock the next difficulty tier (only outside endless)
		var next_tier := DifficultyDatabase.unlock_next_tier(SaveSystem.current_run_difficulty)
		if next_tier != "" and SaveSystem.unlock_difficulty(next_tier):
			var color: Color = DifficultyDatabase.get_data(next_tier).get("color", Color.WHITE)
			EventBus.show_floating_text.emit(
				"%s MODE UNLOCKED!" % next_tier.to_upper(),
				players[0].global_position + Vector3(0, 3.5, 0) if not players.is_empty() else Vector3.ZERO,
				color
			)

	# Save the player
	if not players.is_empty():
		SaveSystem.save_player(players[0])

	# Bump dungeons_completed
	GameState.run_stats.dungeons_completed += 1

	# Fade-in
	root.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.6)


func _on_continue_pressed() -> void:
	# After clearing, also pre-load the save so the next scene picks up the new state
	if SaveSystem.has_save():
		SaveSystem.load_save()
	if SaveSystem.endless_mode:
		# Descend: increment floor counter and reload the dungeon for a fresh layout
		SaveSystem.current_endless_floor += 1
		get_tree().change_scene_to_file(DUNGEON_PATH)
	else:
		get_tree().change_scene_to_file(HUB_PATH)
