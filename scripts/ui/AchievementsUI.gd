extends Control
## Browseable list of all achievements with unlock state + progress bars.
## Instanced on demand from MainMenu and disposes itself on close.

@onready var summary_label: Label = $Dim/Panel/Margin/VBox/Summary
@onready var list_container: VBoxContainer = $Dim/Panel/Margin/VBox/Scroll/List
@onready var close_button: Button = $Dim/Panel/Margin/VBox/CloseButton


func _ready() -> void:
	close_button.pressed.connect(_close)
	_build()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		_close()


func _close() -> void:
	queue_free()


func _build() -> void:
	# Header summary
	var total: int = AchievementDatabase.ACHIEVEMENTS.size()
	var unlocked: int = AchievementManager.unlocked.size()
	summary_label.text = "%d / %d unlocked" % [unlocked, total]

	for c in list_container.get_children():
		c.queue_free()

	# Sort: unlocked first (in catalog order), then locked
	var sorted_ids: Array = []
	for id in AchievementDatabase.all_ids():
		if AchievementManager.unlocked.get(id, false):
			sorted_ids.append(id)
	for id in AchievementDatabase.all_ids():
		if not AchievementManager.unlocked.get(id, false):
			sorted_ids.append(id)

	for id in sorted_ids:
		list_container.add_child(_build_row(id))


func _build_row(id: String) -> Control:
	var def: Dictionary = AchievementDatabase.get_def(id)
	var is_unlocked: bool = AchievementManager.unlocked.get(id, false)

	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 64)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	margin.add_child(hbox)

	# Icon
	var icon := Label.new()
	icon.custom_minimum_size = Vector2(36, 0)
	icon.add_theme_font_size_override("font_size", 28)
	icon.text = "★" if is_unlocked else "✦"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.modulate = Color(1.0, 0.85, 0.30) if is_unlocked else Color(0.40, 0.40, 0.45)
	hbox.add_child(icon)

	# Title + description + (optional progress)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 1)
	hbox.add_child(vbox)

	var title := Label.new()
	title.text = String(def.get("name", "?"))
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.WHITE if is_unlocked else Color(0.6, 0.6, 0.65))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = String(def.get("description", ""))
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.78, 0.78, 0.82) if is_unlocked else Color(0.45, 0.45, 0.50))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	# Counter progress bar (if applicable + not yet unlocked)
	if "counter" in def and not is_unlocked:
		var counter_id: String = def.counter
		var target: int = int(def.target)
		var current: int = int(AchievementManager.counters.get(counter_id, 0))
		var shown: int = min(current, target)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 8)
		bar.max_value = target
		bar.value = shown
		bar.show_percentage = false
		vbox.add_child(bar)
		var prog := Label.new()
		prog.text = "%d / %d" % [shown, target]
		prog.add_theme_font_size_override("font_size", 11)
		prog.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))
		vbox.add_child(prog)

	# Right-side status text
	var status := Label.new()
	status.custom_minimum_size = Vector2(90, 0)
	status.add_theme_font_size_override("font_size", 12)
	status.text = "Unlocked" if is_unlocked else "Locked"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color", Color(0.55, 0.85, 0.45) if is_unlocked else Color(0.55, 0.55, 0.60))
	hbox.add_child(status)

	return row
