extends Control
## Browser for the player's last 20 runs. Entries are pulled from the
## RunHistory autoload. Instanced on demand from PauseMenu; frees on close.

@onready var entry_list: VBoxContainer = $Panel/Margin/VBox/ScrollContainer/EntryList
@onready var close_button: Button = $Panel/Margin/VBox/CloseButton


func _ready() -> void:
	close_button.pressed.connect(_close)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		_close()


func _close() -> void:
	queue_free()


func _refresh() -> void:
	for c in entry_list.get_children():
		c.queue_free()
	if RunHistory.entries.is_empty():
		var hint := Label.new()
		hint.text = "No runs yet."
		hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
		entry_list.add_child(hint)
		return
	for entry in RunHistory.entries:
		entry_list.add_child(_make_row(entry))


func _make_row(entry: Dictionary) -> Control:
	var card := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	var date := Label.new()
	date.text = String(entry.get("date", ""))
	date.add_theme_font_size_override("font_size", 11)
	date.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	date.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(date)

	var outcome := Label.new()
	var is_cleared: bool = entry.get("outcome", "") == "cleared"
	outcome.text = "✓ CLEARED" if is_cleared else "✗ DIED"
	outcome.add_theme_font_size_override("font_size", 13)
	outcome.add_theme_color_override("font_color",
		Color(0.55, 0.85, 0.45) if is_cleared else Color(0.95, 0.45, 0.45))
	header.add_child(outcome)
	vbox.add_child(header)

	var summary := Label.new()
	var t: float = float(entry.get("time", 0.0))
	var time_str: String = "%d:%02d" % [int(t) / 60, int(t) % 60]
	summary.text = "%s Lv %d   ·   %s   ·   %s   ·   %d kills (%d bosses)" % [
		String(entry.get("class", "?")),
		int(entry.get("level", 0)),
		String(entry.get("difficulty", "?")),
		time_str,
		int(entry.get("kills", 0)),
		int(entry.get("bosses", 0)),
	]
	summary.add_theme_font_size_override("font_size", 13)
	vbox.add_child(summary)

	var loot := Label.new()
	loot.text = "%d gold   ·   %d items" % [int(entry.get("gold", 0)), int(entry.get("items", 0))]
	loot.add_theme_font_size_override("font_size", 11)
	loot.add_theme_color_override("font_color", Color(0.78, 0.78, 0.55))
	vbox.add_child(loot)

	var mods: Array = entry.get("modifiers", [])
	if not mods.is_empty():
		var mod_label := Label.new()
		mod_label.text = "Modifiers: %s" % ", ".join(mods)
		mod_label.add_theme_font_size_override("font_size", 10)
		mod_label.add_theme_color_override("font_color", Color(0.65, 0.55, 0.85))
		vbox.add_child(mod_label)

	if not is_cleared and String(entry.get("killer", "")) != "":
		var killer := Label.new()
		killer.text = "Slain by %s" % entry.get("killer", "")
		killer.add_theme_font_size_override("font_size", 11)
		killer.add_theme_color_override("font_color", Color(0.95, 0.55, 0.45))
		vbox.add_child(killer)

	return card
