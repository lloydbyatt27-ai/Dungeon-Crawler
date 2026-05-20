extends Control
## Class selection screen, shown after New Game.
## Stashes the chosen class id on SaveSystem.pending_class so the next Player
## spawn applies the matching preset.

@onready var card_container: HBoxContainer = $Center/VBox/CardRow
@onready var class_name_label: Label = $Center/VBox/DetailPanel/Margin/VBox/ClassName
@onready var role_label: Label = $Center/VBox/DetailPanel/Margin/VBox/RoleLabel
@onready var description_label: Label = $Center/VBox/DetailPanel/Margin/VBox/Description
@onready var stats_label: RichTextLabel = $Center/VBox/DetailPanel/Margin/VBox/StatsLabel
@onready var skills_label: RichTextLabel = $Center/VBox/DetailPanel/Margin/VBox/SkillsLabel
@onready var difficulty_row: HBoxContainer = $Center/VBox/DifficultyRow
@onready var begin_button: Button = $Center/VBox/BeginButton
@onready var back_button: Button = $BackButton

const HUB_PATH: String = "res://scenes/world/HubTown.tscn"
const MAIN_MENU_PATH: String = "res://scenes/ui/MainMenu.tscn"

var _selected_class: String = "Guardian"
var _selected_difficulty: String = "Normal"
var _cards: Array[Button] = []
var _difficulty_buttons: Dictionary = {}


func _ready() -> void:
	_build_cards()
	_build_difficulty_row()
	begin_button.pressed.connect(_on_begin_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_select(_selected_class)
	_select_difficulty(_selected_difficulty)


func _build_difficulty_row() -> void:
	for c in difficulty_row.get_children():
		c.queue_free()
	_difficulty_buttons.clear()
	for tier in DifficultyDatabase.TIER_ORDER:
		var data: Dictionary = DifficultyDatabase.get_data(tier)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(140, 46)
		var unlocked := DifficultyDatabase.is_tier_unlocked(tier, SaveSystem.unlocked_difficulties)
		if unlocked:
			btn.text = tier
			btn.add_theme_color_override("font_color", data.get("color", Color.WHITE))
		else:
			btn.text = "%s 🔒" % tier
			btn.disabled = true
			btn.tooltip_text = "Beat the boss on %s to unlock." % DifficultyDatabase.TIER_ORDER[DifficultyDatabase.TIER_ORDER.find(tier) - 1]
		btn.pressed.connect(_select_difficulty.bind(tier))
		difficulty_row.add_child(btn)
		_difficulty_buttons[tier] = btn


func _select_difficulty(tier: String) -> void:
	if not DifficultyDatabase.is_tier_unlocked(tier, SaveSystem.unlocked_difficulties):
		return
	_selected_difficulty = tier
	for t in _difficulty_buttons:
		var btn: Button = _difficulty_buttons[t]
		if t == tier:
			btn.modulate = Color(1.5, 1.5, 1.5)
		else:
			btn.modulate = Color(0.7, 0.7, 0.7)


func _build_cards() -> void:
	for c in card_container.get_children():
		c.queue_free()
	_cards.clear()
	for class_id in ClassDatabase.all_class_names():
		var data: Dictionary = ClassDatabase.get_class_data(class_id)
		var card := _make_card(class_id, data)
		card_container.add_child(card)
		_cards.append(card)


func _make_card(class_id: String, data: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(140, 180)
	card.text = "%s\n\n%s\n%s" % [
		data.display_name,
		data.get("role", ""),
		data.get("difficulty", ""),
	]
	card.add_theme_color_override("font_color", data.get("body_color", Color.WHITE))
	card.add_theme_color_override("font_hover_color", data.get("body_color", Color.WHITE).lightened(0.2))
	card.pressed.connect(_select.bind(class_id))
	return card


func _select(class_id: String) -> void:
	_selected_class = class_id
	var data: Dictionary = ClassDatabase.get_class_data(class_id)
	class_name_label.text = data.display_name
	class_name_label.add_theme_color_override("font_color", data.get("body_color", Color.WHITE))
	role_label.text = "%s   ·   %s" % [data.get("role", ""), data.get("difficulty", "")]
	description_label.text = data.get("description", "")

	# Stat block
	var stats: Dictionary = data.get("stats", {})
	stats_label.clear()
	stats_label.push_color(Color(0.85, 0.85, 0.85))
	stats_label.add_text("STR  %d    AGI  %d    INT  %d    STA  %d\n" % [
		stats.get("strength", 0),
		stats.get("agility", 0),
		stats.get("intelligence", 0),
		stats.get("stamina", 0),
	])
	stats_label.pop()
	# Per-level growth preview
	var auto: Dictionary = data.get("auto_allocate", {})
	stats_label.push_color(Color(0.65, 0.65, 0.65))
	stats_label.add_text("Per level: ")
	var parts: Array[String] = []
	for attr in auto:
		parts.append("+%d %s" % [auto[attr], attr.to_upper().substr(0, 3)])
	stats_label.add_text(", ".join(parts))
	stats_label.pop()

	# Skill block
	skills_label.clear()
	skills_label.push_color(Color(0.9, 0.85, 0.6))
	skills_label.add_text("Starter Skills\n")
	skills_label.pop()
	for sid in data.get("starter_skills", []):
		var skill_def: Dictionary = SkillSystem.SKILL_CATALOG.get(sid, {})
		if skill_def.is_empty():
			continue
		skills_label.push_color(skill_def.get("color", Color.WHITE))
		skills_label.add_text("• %s" % skill_def.get("display_name", sid))
		skills_label.pop()
		skills_label.push_color(Color(0.6, 0.6, 0.6))
		skills_label.add_text("   (%s)\n" % skill_def.get("type", "").capitalize())
		skills_label.pop()

	# Highlight selected card
	for i in range(_cards.size()):
		var card := _cards[i]
		var card_class := ClassDatabase.all_class_names()[i]
		var card_color: Color = ClassDatabase.get_class_data(card_class).get("body_color", Color.WHITE)
		if card_class == class_id:
			card.modulate = Color(1.4, 1.4, 1.4)
		else:
			card.modulate = card_color.darkened(0.2)


func _on_begin_pressed() -> void:
	# Stash the class + difficulty on the SaveSystem
	SaveSystem.pending_class = _selected_class
	SaveSystem.current_run_difficulty = _selected_difficulty
	SaveSystem.delete_save()
	SaveSystem.pending_load_data = {}
	GameState.run_stats = {
		"monsters_killed": 0, "bosses_defeated": 0, "deaths": 0,
		"gold_earned_total": 0, "items_collected": 0,
		"play_time_seconds": 0.0, "dungeons_completed": 0,
	}
	get_tree().change_scene_to_file(HUB_PATH)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
