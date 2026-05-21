extends Control
## Skill loadout editor. Lets the player swap their three active skills
## (Q / E / R) for any skill in their class's `available_skills` pool.
## Instanced on demand from PauseMenu; queue_frees itself on close.

@onready var slot_row: HBoxContainer = $Panel/Margin/VBox/SlotRow
@onready var pool_row: HBoxContainer = $Panel/Margin/VBox/PoolRow
@onready var description: RichTextLabel = $Panel/Margin/VBox/Description
@onready var close_button: Button = $Panel/Margin/VBox/CloseButton

var _player: PlayerController
var _active: Array[String] = []
var _pool: Array = []
var _selected_slot: int = 0  # 0..2 — slot the player is editing


func _ready() -> void:
	close_button.pressed.connect(_close)
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		_close()
		return
	_player = players[0]
	if _player.stats == null:
		_close()
		return
	# Snapshot the player's loadout into a local working copy. Apply on Close.
	_active.clear()
	for sid in _player.stats.active_skill_ids:
		_active.append(String(sid))
	while _active.size() < 3:
		_active.append("")
	var class_data: Dictionary = ClassDatabase.get_class_data(_player.stats.class_type)
	_pool = class_data.get("available_skills", class_data.get("starter_skills", []))
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		_close()


func _close() -> void:
	_apply_and_save()
	queue_free()


func _apply_and_save() -> void:
	if _player == null or _player.stats == null:
		return
	# Drop any empty slots — clamp to actual skills only
	var trimmed: Array[String] = []
	for sid in _active:
		if sid != "":
			trimmed.append(sid)
	if trimmed.is_empty():
		return
	_player.stats.active_skill_ids = trimmed
	if _player.skill_system:
		_player.skill_system.set_active_skills(trimmed)


# --- Rendering ---------------------------------------------------

func _refresh() -> void:
	for c in slot_row.get_children(): c.queue_free()
	for c in pool_row.get_children(): c.queue_free()

	var slot_keys := ["Q", "E", "R"]
	for i in range(3):
		slot_row.add_child(_make_slot_button(i, slot_keys[i]))

	for sid in _pool:
		pool_row.add_child(_make_pool_button(String(sid)))

	_paint_description()


func _make_slot_button(slot_idx: int, key: String) -> Control:
	var sid: String = _active[slot_idx] if slot_idx < _active.size() else ""
	var def: Dictionary = SkillSystem.SKILL_CATALOG.get(sid, {})
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(180, 64)
	if def.is_empty():
		btn.text = "[ %s ]\nempty" % key
		btn.modulate = Color(0.5, 0.5, 0.55)
	else:
		btn.text = "%s\n%s" % [key, def.get("display_name", sid)]
		btn.add_theme_color_override("font_color", def.get("color", Color.WHITE))
	if slot_idx == _selected_slot:
		btn.modulate = Color(1.4, 1.2, 0.7)
	btn.pressed.connect(func(): _selected_slot = slot_idx; _refresh())
	return btn


func _make_pool_button(sid: String) -> Control:
	var def: Dictionary = SkillSystem.SKILL_CATALOG.get(sid, {})
	if def.is_empty():
		return Control.new()
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(110, 50)
	btn.text = def.get("display_name", sid)
	btn.add_theme_color_override("font_color", def.get("color", Color.WHITE))
	btn.add_theme_font_size_override("font_size", 12)
	# Disabled if already in the active set (no duplicates)
	if sid in _active:
		btn.disabled = true
		btn.tooltip_text = "Already equipped"
	btn.pressed.connect(_assign_to_slot.bind(sid))
	return btn


func _assign_to_slot(sid: String) -> void:
	if _selected_slot < 0 or _selected_slot >= 3:
		return
	# Disallow duplicates: if sid is already in another slot, swap it
	for i in range(_active.size()):
		if _active[i] == sid and i != _selected_slot:
			_active[i] = _active[_selected_slot]
			break
	_active[_selected_slot] = sid
	_refresh()


func _paint_description() -> void:
	description.clear()
	var sid: String = _active[_selected_slot] if _selected_slot < _active.size() else ""
	var def: Dictionary = SkillSystem.SKILL_CATALOG.get(sid, {})
	if def.is_empty():
		description.add_text("Pick a skill from the pool to fill this slot.")
		return
	description.push_color(def.get("color", Color.WHITE))
	description.add_text(def.get("display_name", sid))
	description.pop()
	description.newline()
	description.push_color(Color(0.7, 0.7, 0.75))
	var kind: String = String(def.get("type", "")).capitalize()
	var mana: float = float(def.get("mana_cost", 0.0))
	var cd: float = float(def.get("cooldown", 0.0))
	description.add_text("%s   ·   %d mana   ·   %.1fs cooldown" % [kind, int(mana), cd])
	description.pop()
	if def.has("base_damage"):
		description.newline()
		description.add_text("Base damage: %d  (scales with %s)" % [
			int(def.base_damage), String(def.get("scaling_attr", ""))
		])
	if def.get("type", "") == "buff":
		description.newline()
		description.add_text("Grants +%.0f%% %s for %.0fs" % [
			float(def.get("buff_amount", 0.0)) * 100.0,
			String(def.get("buff_stat", "")).replace("_bonus", "").replace("_", " "),
			float(def.get("duration", 0.0))
		])
