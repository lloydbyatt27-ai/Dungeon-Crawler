extends CanvasLayer
## Bestiary browser. Lists every enemy species the Bestiary autoload has
## recorded a kill for, along with kill count and the highest HP seen
## (so endless-mode floors show off how scaled-up the creature got).

@onready var root: Control = $Root
@onready var stats_label: Label = $Root/Panel/Margin/VBox/StatsLabel
@onready var entry_list: VBoxContainer = $Root/Panel/Margin/VBox/ScrollContainer/EntryList
@onready var close_button: Button = $Root/Panel/Margin/VBox/CloseButton


func _ready() -> void:
	root.visible = false
	close_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if root.visible and event is InputEventKey and event.pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			close()


func open() -> void:
	root.visible = true
	_refresh()


func close() -> void:
	# Both modes are supported: instantiated-on-demand (PauseMenu pattern)
	# frees itself; preloaded-in-scene variants just hide their root.
	if get_parent() and get_parent().name == "PauseMenu":
		queue_free()
	else:
		root.visible = false


func _refresh() -> void:
	for c in entry_list.get_children():
		c.queue_free()
	stats_label.text = "%d species   ·   %d total kills" % [
		Bestiary.unique_species_count(),
		Bestiary.total_kills(),
	]
	# Sort by kill count desc so the player's favourites bubble up
	var sorted_keys: Array = Bestiary.entries.keys()
	sorted_keys.sort_custom(func(a, b):
		return int(Bestiary.entries[a].get("kills", 0)) > int(Bestiary.entries[b].get("kills", 0))
	)
	if sorted_keys.is_empty():
		var hint := Label.new()
		hint.text = "Slay something to fill these pages."
		hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
		entry_list.add_child(hint)
		return
	for key in sorted_keys:
		var entry: Dictionary = Bestiary.entries[key]
		entry_list.add_child(_make_row(entry))


func _make_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 32)
	row.add_theme_constant_override("separation", 12)

	var name_label := Label.new()
	name_label.text = String(entry.get("display", "?"))
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)

	var kills := Label.new()
	kills.text = "× %d slain" % int(entry.get("kills", 0))
	kills.add_theme_font_size_override("font_size", 13)
	kills.add_theme_color_override("font_color", Color(0.85, 0.85, 0.55))
	kills.custom_minimum_size = Vector2(110, 0)
	kills.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(kills)

	var hp := Label.new()
	hp.text = "%d HP record" % int(entry.get("max_hp_seen", 0.0))
	hp.add_theme_font_size_override("font_size", 12)
	hp.add_theme_color_override("font_color", Color(0.85, 0.55, 0.55))
	hp.custom_minimum_size = Vector2(130, 0)
	hp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(hp)
	return row
