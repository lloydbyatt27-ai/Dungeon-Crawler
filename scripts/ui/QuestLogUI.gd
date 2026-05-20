extends CanvasLayer
## Quest log + accept screen. Toggled with J anywhere, or via the Sage NPC.
## Left column = available quests (with Accept buttons), right column =
## currently active quests with progress bars.

@onready var root: Control = $Root
@onready var available_box: VBoxContainer = $Root/Panel/Margin/VBox/Columns/AvailableCol/List
@onready var active_box: VBoxContainer = $Root/Panel/Margin/VBox/Columns/ActiveCol/List
@onready var daily_box: VBoxContainer = $Root/Panel/Margin/VBox/Columns/ActiveCol/DailyBox
@onready var close_button: Button = $Root/Panel/Margin/VBox/CloseButton

var _player: PlayerController


func _ready() -> void:
	root.visible = false
	close_button.pressed.connect(close)
	QuestSystem.quests_changed.connect(_refresh)
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]
	for g in get_tree().get_nodes_in_group("quest_giver"):
		if g.has_signal("opened") and not g.opened.is_connected(open):
			g.opened.connect(open)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quest_log"):
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


func _refresh() -> void:
	_rebuild_available()
	_rebuild_daily()
	_rebuild_active()


func _rebuild_available() -> void:
	for c in available_box.get_children():
		c.queue_free()
	if _player == null or _player.stats == null:
		return
	var ids := QuestDatabase.available_for(QuestSystem.active_ids(), _player.stats.completed_quest_ids, 5)
	if ids.is_empty():
		var lbl := Label.new()
		lbl.text = "No new quests available."
		lbl.modulate = Color(0.6, 0.6, 0.65)
		available_box.add_child(lbl)
		return
	for id in ids:
		var def: Dictionary = QuestDatabase.QUESTS[id]
		available_box.add_child(_make_available_row(id, def))


func _rebuild_daily() -> void:
	for c in daily_box.get_children():
		c.queue_free()
	var q: Quest = QuestSystem.daily_quest
	if q == null:
		return
	var title := Label.new()
	title.text = "Daily Bounty"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	daily_box.add_child(title)
	# A bordered card with the daily details
	var panel := PanelContainer.new()
	panel.modulate = Color(1.05, 0.95, 0.85, 1.0)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	margin.add_child(v)
	var name_label := Label.new()
	name_label.text = q.title
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	v.add_child(name_label)
	var desc_label := Label.new()
	desc_label.text = q.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(desc_label)
	if q.completed:
		var done := Label.new()
		done.text = "✓ Completed — reward claimed."
		done.add_theme_font_size_override("font_size", 12)
		done.add_theme_color_override("font_color", Color(0.55, 0.95, 0.45))
		v.add_child(done)
	else:
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 12)
		bar.max_value = q.target
		bar.value = q.progress
		bar.show_percentage = false
		v.add_child(bar)
		var prog := Label.new()
		prog.text = "%s   ·   %d gold, %d XP  (x3 bounty)" % [q.progress_text(), q.gold_reward, q.xp_reward]
		prog.add_theme_font_size_override("font_size", 11)
		prog.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		v.add_child(prog)
	daily_box.add_child(panel)
	var sep := HSeparator.new()
	daily_box.add_child(sep)


func _rebuild_active() -> void:
	for c in active_box.get_children():
		c.queue_free()
	if QuestSystem.active_quests.is_empty():
		var lbl := Label.new()
		lbl.text = "(No active quests)"
		lbl.modulate = Color(0.6, 0.6, 0.65)
		active_box.add_child(lbl)
		return
	for q in QuestSystem.active_quests:
		active_box.add_child(_make_active_row(q))


func _make_available_row(id: String, def: Dictionary) -> Control:
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(0, 70)
	vbox.theme_override_constants = {}
	var title := Label.new()
	title.text = def.title
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)
	var desc := Label.new()
	desc.text = def.description
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	desc.add_theme_font_size_override("font_size", 12)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)
	var reward := Label.new()
	reward.text = "Reward: %d gold, %d XP" % [int(def.get("gold_reward", 0)), int(def.get("xp_reward", 0))]
	reward.add_theme_color_override("font_color", Color(0.55, 0.85, 0.45))
	reward.add_theme_font_size_override("font_size", 12)
	vbox.add_child(reward)
	var btn := Button.new()
	btn.text = "Accept"
	btn.custom_minimum_size = Vector2(0, 28)
	btn.disabled = QuestSystem.active_quests.size() >= QuestSystem.MAX_ACTIVE
	btn.pressed.connect(_accept.bind(id))
	vbox.add_child(btn)
	# Subtle separator
	var sep := HSeparator.new()
	vbox.add_child(sep)
	return vbox


func _make_active_row(q: Quest) -> Control:
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(0, 70)
	var title := Label.new()
	title.text = q.title
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)
	var desc := Label.new()
	desc.text = q.description
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	desc.add_theme_font_size_override("font_size", 12)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 14)
	bar.max_value = q.target
	bar.value = q.progress
	bar.show_percentage = false
	vbox.add_child(bar)
	var prog := Label.new()
	prog.text = q.progress_text()
	prog.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	prog.add_theme_font_size_override("font_size", 12)
	vbox.add_child(prog)
	var sep := HSeparator.new()
	vbox.add_child(sep)
	return vbox


func _accept(id: String) -> void:
	if QuestSystem.accept(id):
		# Refreshed via the quests_changed signal
		pass
