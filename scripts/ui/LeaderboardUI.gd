extends Control
## Local leaderboard. Pulls records from the various meta-state systems:
##   - Active character: level, paragon, best endless floor
##   - Cross-character (meta): best Greater Rift tier
##   - BossTimer: per-boss best kill times
##   - Bestiary: total kills

@onready var content: VBoxContainer = $Panel/Margin/VBox/ScrollContainer/Content
@onready var close_button: Button = $Panel/Margin/VBox/CloseButton


func _ready() -> void:
	close_button.pressed.connect(_close)
	_build()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		_close()


func _close() -> void:
	queue_free()


func _build() -> void:
	for c in content.get_children():
		c.queue_free()

	# --- Active character ---
	var players := get_tree().get_nodes_in_group("player")
	var player: Node = players[0] if not players.is_empty() else null
	_add_section("This Character")
	if player and "stats" in player and player.stats:
		var s = player.stats
		_add_row("Class", String(s.class_type))
		_add_row("Level", "%d  (P%d)" % [s.level, s.paragon_level] if s.paragon_level > 0 else "%d" % s.level)
		_add_row("Best Endless Floor", "%d" % s.best_endless_floor if s.best_endless_floor > 0 else "—")
	else:
		_add_dim_row("(no character loaded)")

	# --- Cross-character meta ---
	_add_section("Records")
	_add_row("Best Greater Rift", "T%d" % SaveSystem.rift_best_tier if SaveSystem.rift_best_tier > 0 else "—")
	_add_row("Difficulties Unlocked", ", ".join(SaveSystem.unlocked_difficulties))
	_add_row("Classes Unlocked", "%d / %d" % [SaveSystem.unlocked_classes.size(), ClassDatabase.CLASSES.size()])
	_add_row("Dungeons Cleared", "%d" % SaveSystem.meta_dungeons_completed)

	# --- Boss kill times ---
	_add_section("Boss Records")
	if BossTimer.best_times.is_empty():
		_add_dim_row("Slay a boss to record a time.")
	else:
		var keys: Array = BossTimer.best_times.keys()
		keys.sort_custom(func(a, b):
			return float(BossTimer.best_times[a]) < float(BossTimer.best_times[b])
		)
		for k in keys:
			_add_row(String(k), BossTimer.format_time(float(BossTimer.best_times[k])))

	# --- Bestiary totals ---
	_add_section("Bestiary")
	_add_row("Species Logged", "%d" % Bestiary.unique_species_count())
	_add_row("Total Kills", "%d" % Bestiary.total_kills())


func _add_section(title: String) -> void:
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1, 0.78, 0.35))
	content.add_child(lbl)


func _add_row(label: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := Label.new()
	name_label.text = label
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.82))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var val_label := Label.new()
	val_label.text = value
	val_label.add_theme_font_size_override("font_size", 13)
	val_label.add_theme_color_override("font_color", Color(1, 1, 1))
	row.add_child(val_label)
	content.add_child(row)


func _add_dim_row(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	content.add_child(lbl)
