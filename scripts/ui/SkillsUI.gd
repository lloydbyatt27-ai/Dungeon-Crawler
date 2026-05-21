extends CanvasLayer
## Skills panel — spend unspent_skill_points to upgrade the player's active
## skills. Open / close with the `skill_tree` action (default K).

@onready var root: Control = $Root
@onready var points_label: Label = $Root/Panel/Margin/VBox/PointsLabel
@onready var skill_list: VBoxContainer = $Root/Panel/Margin/VBox/SkillList
@onready var close_button: Button = $Root/Panel/Margin/VBox/CloseButton

var _player: PlayerController


func _ready() -> void:
	root.visible = false
	close_button.pressed.connect(close)
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]
	EventBus.player_stats_changed.connect(_refresh_if_open)
	EventBus.player_leveled_up.connect(_on_levelup)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill_tree"):
		toggle()
	elif root.visible and event is InputEventKey and event.pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			close()


func toggle() -> void:
	if root.visible:
		close()
	else:
		open()


func open() -> void:
	root.visible = true
	_refresh()


func close() -> void:
	root.visible = false


func _refresh_if_open() -> void:
	if root.visible:
		_refresh()


func _on_levelup(_lvl: int) -> void:
	# Auto-open on level-up so the player notices the new skill point.
	# Actually no — that's intrusive. Just refresh if open.
	_refresh_if_open()


func _refresh() -> void:
	if _player == null or _player.stats == null:
		return
	for c in skill_list.get_children():
		c.queue_free()
	points_label.text = "Skill points available: %d" % _player.stats.unspent_skill_points

	var skills: Array = _player.skill_system.active_skills if _player.skill_system else []
	for sid in skills:
		var def: Dictionary = SkillSystem.SKILL_CATALOG.get(sid, {})
		if def.is_empty():
			continue
		skill_list.add_child(_make_skill_row(sid, def))


func _make_skill_row(skill_id: String, def: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 42)
	row.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(160, 38)
	name_label.text = def.display_name
	name_label.add_theme_color_override("font_color", def.get("color", Color.WHITE))
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 15)
	row.add_child(name_label)

	var rank: int = _player.stats.skill_rank(skill_id)
	var maxr: int = CharacterStats.MAX_SKILL_RANK
	var pip_text := ""
	for i in range(maxr):
		pip_text += "●" if i < rank else "○"
	var pip_label := Label.new()
	pip_label.text = pip_text
	pip_label.add_theme_font_size_override("font_size", 18)
	pip_label.custom_minimum_size = Vector2(70, 38)
	pip_label.add_theme_color_override("font_color", Color(1, 0.78, 0.35))
	pip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(pip_label)

	var effect_label := Label.new()
	effect_label.custom_minimum_size = Vector2(140, 38)
	effect_label.text = _effect_text(def, rank)
	effect_label.add_theme_font_size_override("font_size", 11)
	effect_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.78))
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(effect_label)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(70, 32)
	if rank >= maxr:
		btn.text = "Max"
		btn.disabled = true
	elif _player.stats.unspent_skill_points <= 0:
		btn.text = "Rank Up"
		btn.disabled = true
	else:
		btn.text = "Rank Up"
		btn.pressed.connect(_rank_up.bind(skill_id))
	row.add_child(btn)
	return row


func _effect_text(def: Dictionary, rank: int) -> String:
	if def.get("type", "") == "buff":
		var base_dur: float = def.get("duration", 0.0)
		return "Dur %.0fs → %.0fs" % [base_dur, base_dur * (1.0 + 0.25 * rank)]
	# Damage skills: show damage multiplier and cd reduction
	return "Dmg ×%.2f   CD ×%.2f" % [1.0 + 0.20 * rank, max(0.4, 1.0 - 0.10 * rank)]


func _rank_up(skill_id: String) -> void:
	if _player == null or _player.stats == null:
		return
	if _player.stats.invest_skill_point(skill_id):
		EventBus.player_stats_changed.emit()
		EventBus.show_floating_text.emit(
			"%s rank up!" % SkillSystem.SKILL_CATALOG[skill_id].display_name,
			_player.global_position + Vector3(0, 2.4, 0),
			Color(1, 0.78, 0.35)
		)
		_refresh()
