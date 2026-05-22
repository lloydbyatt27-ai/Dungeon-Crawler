extends CanvasLayer
## Esc toggles a pause overlay with Resume / Settings / Quit-to-Hub / Quit-to-Menu.
## Sub-panel for audio sliders writes to user://settings.json on change.
## process_mode is PROCESS_MODE_WHEN_PAUSED so we still respond when the
## tree is paused.

@onready var root: Control = $Root
@onready var main_panel: PanelContainer = $Root/MainPanel
@onready var settings_panel: PanelContainer = $Root/SettingsPanel

@onready var resume_button: Button = $Root/MainPanel/Margin/VBox/ResumeButton
@onready var settings_button: Button = $Root/MainPanel/Margin/VBox/SettingsButton
@onready var achievements_button: Button = $Root/MainPanel/Margin/VBox/AchievementsButton
@onready var bestiary_button: Button = $Root/MainPanel/Margin/VBox/BestiaryButton
@onready var mercenary_button: Button = $Root/MainPanel/Margin/VBox/MercenaryButton
@onready var loadout_button: Button = $Root/MainPanel/Margin/VBox/LoadoutButton
@onready var modifiers_button: Button = $Root/MainPanel/Margin/VBox/ModifiersButton
@onready var run_history_button: Button = $Root/MainPanel/Margin/VBox/RunHistoryButton
@onready var leaderboard_button: Button = $Root/MainPanel/Margin/VBox/LeaderboardButton
@onready var quit_hub_button: Button = $Root/MainPanel/Margin/VBox/QuitHubButton
@onready var quit_menu_button: Button = $Root/MainPanel/Margin/VBox/QuitMenuButton

@onready var master_slider: HSlider = $Root/SettingsPanel/Margin/VBox/Master/MasterSlider
@onready var sfx_slider: HSlider = $Root/SettingsPanel/Margin/VBox/SFX/SFXSlider
@onready var music_slider: HSlider = $Root/SettingsPanel/Margin/VBox/Music/MusicSlider
@onready var master_label: Label = $Root/SettingsPanel/Margin/VBox/Master/MasterValue
@onready var sfx_label: Label = $Root/SettingsPanel/Margin/VBox/SFX/SFXValue
@onready var music_label: Label = $Root/SettingsPanel/Margin/VBox/Music/MusicValue
@onready var controls_box: VBoxContainer = $Root/SettingsPanel/Margin/VBox/ControlsBox
@onready var video_box: VBoxContainer = $Root/SettingsPanel/Margin/VBox/VideoBox
@onready var loot_row: HBoxContainer = $Root/SettingsPanel/Margin/VBox/LootRow
@onready var back_button: Button = $Root/SettingsPanel/Margin/VBox/BackButton

# Key-capture state — set while we wait for the next keypress after a Rebind click
var _capturing_action: String = ""
var _capture_button: Button = null

const HUB_PATH: String = "res://scenes/world/HubTown.tscn"
const MAIN_MENU_PATH: String = "res://scenes/ui/MainMenu.tscn"

# Whether the current scene should offer "Quit to Hub" (only relevant in the
# dungeon — in the hub it's redundant)
@export var show_quit_to_hub: bool = true


func _ready() -> void:
	root.visible = false
	settings_panel.visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Hide "Quit to Hub" in the hub itself
	quit_hub_button.visible = show_quit_to_hub

	resume_button.pressed.connect(close)
	settings_button.pressed.connect(_show_settings)
	achievements_button.pressed.connect(_show_achievements)
	bestiary_button.pressed.connect(_show_bestiary)
	mercenary_button.pressed.connect(_show_mercenary)
	loadout_button.pressed.connect(_show_loadout)
	modifiers_button.pressed.connect(_show_modifiers)
	run_history_button.pressed.connect(_show_run_history)
	leaderboard_button.pressed.connect(_show_leaderboard)
	quit_hub_button.pressed.connect(_quit_to_hub)
	quit_menu_button.pressed.connect(_quit_to_menu)
	back_button.pressed.connect(_show_main)

	# Bind sliders to AudioManager
	master_slider.value = AudioManager.master_volume
	sfx_slider.value = AudioManager.sfx_volume
	music_slider.value = AudioManager.music_volume
	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	_refresh_volume_labels()
	_build_video_settings()
	_build_loot_filter_row()
	_build_controls()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			if root.visible:
				close()
			else:
				open()


func open() -> void:
	root.visible = true
	settings_panel.visible = false
	main_panel.visible = true
	get_tree().paused = true


func close() -> void:
	root.visible = false
	get_tree().paused = false


func _show_settings() -> void:
	main_panel.visible = false
	settings_panel.visible = true


func _show_achievements() -> void:
	# Instance the same AchievementsUI used by the Main Menu, anchored above
	# this pause panel by setting a higher Control z-index. Disposes itself.
	var ach_ui = preload("res://scenes/ui/AchievementsUI.tscn").instantiate()
	add_child(ach_ui)


func _show_bestiary() -> void:
	var bes_ui = preload("res://scenes/ui/BestiaryUI.tscn").instantiate()
	add_child(bes_ui)
	if bes_ui.has_method("open"):
		bes_ui.open()


func _show_loadout() -> void:
	var ui = preload("res://scenes/ui/SkillLoadoutUI.tscn").instantiate()
	add_child(ui)


func _show_run_history() -> void:
	var ui = preload("res://scenes/ui/RunHistoryUI.tscn").instantiate()
	add_child(ui)


func _show_leaderboard() -> void:
	var ui = preload("res://scenes/ui/LeaderboardUI.tscn").instantiate()
	add_child(ui)


# --- Run modifiers picker ----------------------------------------

var _mod_popup: PanelContainer = null


func _show_modifiers() -> void:
	if _mod_popup:
		_mod_popup.queue_free()
		_mod_popup = null
	_mod_popup = PanelContainer.new()
	_mod_popup.set_anchors_preset(Control.PRESET_CENTER)
	_mod_popup.custom_minimum_size = Vector2(440, 0)
	_mod_popup.position = Vector2(-220, -240)
	root.add_child(_mod_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_mod_popup.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Run Modifiers"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.78, 0.35))
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "Opt-in challenges. Effects stack. Applied to all subsequent dungeons until cleared."
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)

	for mod_id in DifficultyModifierDatabase.all_ids():
		var data: Dictionary = DifficultyModifierDatabase.get_modifier(mod_id)
		var active: bool = mod_id in SaveSystem.active_modifiers
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.text = "%s%s\n%s" % ["✓ " if active else "  ", data.name, data.desc]
		btn.add_theme_color_override("font_color", data.color if active else Color(0.85, 0.85, 0.9))
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_toggle_modifier.bind(mod_id))
		vbox.add_child(btn)

	var clear := Button.new()
	clear.text = "Clear All"
	clear.custom_minimum_size = Vector2(0, 28)
	clear.pressed.connect(_clear_modifiers)
	vbox.add_child(clear)

	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(0, 28)
	close.pressed.connect(_close_mod_popup)
	vbox.add_child(close)


func _toggle_modifier(id: String) -> void:
	SaveSystem.toggle_modifier(id)
	_close_mod_popup()
	_show_modifiers()


func _clear_modifiers() -> void:
	SaveSystem.clear_modifiers()
	_close_mod_popup()
	_show_modifiers()


func _close_mod_popup() -> void:
	if _mod_popup:
		_mod_popup.queue_free()
		_mod_popup = null


# --- Mercenary hire / dismiss ---------------------------------

var _merc_popup: PanelContainer = null


func _show_mercenary() -> void:
	if _merc_popup:
		_merc_popup.queue_free()
		_merc_popup = null
	_merc_popup = PanelContainer.new()
	_merc_popup.set_anchors_preset(Control.PRESET_CENTER)
	_merc_popup.custom_minimum_size = Vector2(360, 0)
	_merc_popup.position = Vector2(-180, -180)
	root.add_child(_merc_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_merc_popup.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Mercenary Hall"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.78, 0.35))
	vbox.add_child(title)

	var subtitle := Label.new()
	if MercenarySystem.has_active_merc():
		var lv := MercenarySystem.level
		var xp_now := MercenarySystem.xp
		var xp_next := MercenarySystem.xp_for_next()
		var spec_str := ""
		var spec_data := MercenarySystem.current_spec_data()
		if not spec_data.is_empty():
			spec_str = "   ·   %s" % spec_data.get("name", "")
		subtitle.text = "Hired: %s   ·   Lv %d   ·   %d / %d XP%s" % [
			MercenarySystem.current_data().get("display_name", "?"),
			lv, xp_now, xp_next, spec_str
		]
		subtitle.add_theme_color_override("font_color", Color(0.55, 0.85, 0.45))
	else:
		subtitle.text = "No companion hired."
		subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	subtitle.add_theme_font_size_override("font_size", 12)
	vbox.add_child(subtitle)

	# Specialization picker — only shows once unlocked and not yet chosen
	if MercenarySystem.spec_unlocked() and MercenarySystem.specialization == "":
		var spec_header := Label.new()
		spec_header.text = "Choose a specialization (permanent)"
		spec_header.add_theme_font_size_override("font_size", 13)
		spec_header.add_theme_color_override("font_color", Color(1, 0.78, 0.35))
		vbox.add_child(spec_header)
		var merc_specs: Array = MercenarySystem.SPECIALIZATIONS.get(
			_spec_root_id(MercenarySystem.current_type), []
		)
		for spec in merc_specs:
			var spec_btn := Button.new()
			spec_btn.custom_minimum_size = Vector2(0, 36)
			spec_btn.text = "%s — %s" % [spec.name, spec.desc]
			spec_btn.add_theme_font_size_override("font_size", 12)
			spec_btn.pressed.connect(_pick_spec.bind(String(spec.id)))
			vbox.add_child(spec_btn)

	# Hire rows
	var player_gold: int = 0
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0].stats:
		player_gold = players[0].stats.gold
	for merc_id in MercenarySystem.MERC_TYPES:
		var data: Dictionary = MercenarySystem.MERC_TYPES[merc_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var info := Label.new()
		info.text = "%s — %s" % [data.display_name, data.role]
		info.add_theme_font_size_override("font_size", 12)
		info.add_theme_color_override("font_color", data.body_color)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var btn := Button.new()
		btn.text = "Hire  %dg" % int(data.hire_cost)
		btn.custom_minimum_size = Vector2(110, 26)
		btn.add_theme_font_size_override("font_size", 12)
		if player_gold < int(data.hire_cost) or MercenarySystem.current_type == merc_id:
			btn.disabled = true
		btn.pressed.connect(_hire_merc.bind(merc_id, int(data.hire_cost)))
		row.add_child(btn)
		vbox.add_child(row)

	# Dismiss
	if MercenarySystem.has_active_merc():
		var dismiss_btn := Button.new()
		dismiss_btn.text = "Dismiss companion"
		dismiss_btn.custom_minimum_size = Vector2(0, 28)
		dismiss_btn.pressed.connect(_dismiss_merc)
		vbox.add_child(dismiss_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 28)
	close_btn.pressed.connect(_close_merc_popup)
	vbox.add_child(close_btn)


func _hire_merc(merc_id: String, cost: int) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty() or players[0].stats == null:
		return
	var p = players[0]
	if p.stats.gold < cost:
		return
	# If there's already a different merc, despawn it before swapping
	MercenarySystem.despawn_active()
	p.stats.gold -= cost
	EventBus.player_gold_changed.emit(p.stats.gold)
	MercenarySystem.hire(merc_id)
	# Spawn it next to the player so it joins the current scene
	if p.has_method("_spawn_mercenary_if_hired"):
		p._spawn_mercenary_if_hired()
	EventBus.show_floating_text.emit(
		"Hired %s" % MercenarySystem.current_data().get("display_name", "Mercenary"),
		p.global_position + Vector3(0, 2.4, 0),
		Color(0.55, 0.85, 0.45)
	)
	_close_merc_popup()
	_show_mercenary()


func _dismiss_merc() -> void:
	MercenarySystem.despawn_active()
	MercenarySystem.dismiss()
	_close_merc_popup()
	_show_mercenary()


func _close_merc_popup() -> void:
	if _merc_popup:
		_merc_popup.queue_free()
		_merc_popup = null


## Map full merc type id ("warrior") to the spec table key — currently
## identical, but kept as a function so future warrior_alt variants can
## still share specs.
func _spec_root_id(merc_type: String) -> String:
	return merc_type


func _pick_spec(spec_id: String) -> void:
	if MercenarySystem.choose_spec(spec_id):
		EventBus.show_floating_text.emit(
			"Spec chosen: %s" % spec_id.capitalize(),
			Vector3.ZERO,
			Color(1, 0.78, 0.35)
		)
	_close_merc_popup()
	_show_mercenary()


func _show_main() -> void:
	settings_panel.visible = false
	main_panel.visible = true


func _quit_to_hub() -> void:
	# Save the run state so the hub picks up what you collected
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		SaveSystem.save_player(players[0])
		SaveSystem.load_save()
	get_tree().paused = false
	get_tree().change_scene_to_file(HUB_PATH)


func _quit_to_menu() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		SaveSystem.save_player(players[0])
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_master_changed(v: float) -> void:
	AudioManager.master_volume = v
	_refresh_volume_labels()
	AudioManager.save_settings()


func _on_sfx_changed(v: float) -> void:
	AudioManager.sfx_volume = v
	_refresh_volume_labels()
	AudioManager.save_settings()


func _on_music_changed(v: float) -> void:
	AudioManager.music_volume = v
	_refresh_volume_labels()
	AudioManager.save_settings()


func _refresh_volume_labels() -> void:
	master_label.text = "%d%%" % int(AudioManager.master_volume * 100)
	sfx_label.text = "%d%%" % int(AudioManager.sfx_volume * 100)
	music_label.text = "%d%%" % int(AudioManager.music_volume * 100)


# --- Video settings -----------------------------------------------

func _build_video_settings() -> void:
	for c in video_box.get_children():
		c.queue_free()
	# Fullscreen
	video_box.add_child(_video_toggle("Fullscreen", GameSettings.fullscreen,
		func(v): GameSettings.set_fullscreen(v)))
	# VSync
	video_box.add_child(_video_toggle("VSync", GameSettings.vsync,
		func(v): GameSettings.set_vsync(v)))
	# Damage numbers
	video_box.add_child(_video_toggle("Damage Numbers", GameSettings.damage_numbers_enabled,
		func(v): GameSettings.set_damage_numbers_enabled(v)))
	# Max FPS — segmented buttons
	video_box.add_child(_video_fps_row())
	# Camera zoom — slider
	video_box.add_child(_video_slider(
		"Camera Zoom", 10.0, 24.0, 0.5, GameSettings.camera_zoom,
		func(v): GameSettings.set_camera_zoom(v),
		func(v): return "%.0f" % v
	))
	# Screen shake
	video_box.add_child(_video_slider(
		"Screen Shake", 0.0, 1.5, 0.05, GameSettings.screen_shake_scale,
		func(v): GameSettings.set_screen_shake_scale(v),
		func(v): return "%.0f%%" % (v * 100.0)
	))


func _video_toggle(label_text: String, initial: bool, on_changed: Callable) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 28)
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var btn := CheckButton.new()
	btn.button_pressed = initial
	btn.toggled.connect(on_changed)
	row.add_child(btn)
	return row


func _video_fps_row() -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 28)
	row.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = "Max FPS"
	label.custom_minimum_size = Vector2(140, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	for fps in GameSettings.FPS_OPTIONS:
		var btn := Button.new()
		btn.text = "∞" if fps == 0 else str(fps)
		btn.custom_minimum_size = Vector2(0, 24)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 11)
		if fps == GameSettings.max_fps:
			btn.modulate = Color(1.0, 0.85, 0.4)
			btn.disabled = true
		btn.pressed.connect(func():
			GameSettings.set_max_fps(fps)
			_build_video_settings()
		)
		row.add_child(btn)
	return row


func _video_slider(label_text: String, min_v: float, max_v: float, step: float,
		initial: float, on_changed: Callable, format: Callable) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 28)
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(140, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value_label := Label.new()
	value_label.text = format.call(initial)
	value_label.custom_minimum_size = Vector2(60, 0)
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	slider.value_changed.connect(func(v):
		on_changed.call(v)
		value_label.text = format.call(v)
	)
	return row


# --- Loot filter --------------------------------------------------

const LOOT_FILTER_LABELS: Array = ["All", "Uncommon+", "Rare+", "Epic+", "Legendary"]


func _build_loot_filter_row() -> void:
	for c in loot_row.get_children():
		c.queue_free()
	var cur := SaveSystem.loot_filter_min_rarity
	for i in range(LOOT_FILTER_LABELS.size()):
		var btn := Button.new()
		btn.text = LOOT_FILTER_LABELS[i]
		btn.custom_minimum_size = Vector2(0, 28)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 12)
		if i == cur:
			btn.modulate = Color(1.0, 0.9, 0.5)
			btn.disabled = true
		btn.pressed.connect(_set_loot_filter.bind(i))
		loot_row.add_child(btn)


func _set_loot_filter(value: int) -> void:
	SaveSystem.set_loot_filter(value)
	_build_loot_filter_row()


# --- Controls / key rebinding -----------------------------------

func _build_controls() -> void:
	for c in controls_box.get_children():
		c.queue_free()
	for action in ControlsManager.REBINDABLE:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 30)
		var label := Label.new()
		label.text = ControlsManager.LABELS.get(action, action.capitalize())
		label.custom_minimum_size = Vector2(140, 0)
		label.add_theme_font_size_override("font_size", 13)
		row.add_child(label)
		var btn := Button.new()
		btn.text = ControlsManager.get_current_key_text(action)
		btn.custom_minimum_size = Vector2(140, 28)
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(_start_capture.bind(action, btn))
		row.add_child(btn)
		controls_box.add_child(row)


func _start_capture(action: String, btn: Button) -> void:
	# If something else was already capturing, cancel it first
	if _capture_button:
		_capture_button.text = ControlsManager.get_current_key_text(_capturing_action)
	_capturing_action = action
	_capture_button = btn
	btn.text = "Press a key..."


func _input(event: InputEvent) -> void:
	# Only consume input when actively waiting for a key for a rebind
	if _capturing_action == "" or _capture_button == null:
		return
	if not (event is InputEventKey):
		return
	var ev := event as InputEventKey
	if not ev.pressed or ev.echo:
		return
	# Esc cancels the capture without changing anything
	if ev.keycode == KEY_ESCAPE:
		_capture_button.text = ControlsManager.get_current_key_text(_capturing_action)
		_clear_capture()
		get_viewport().set_input_as_handled()
		return
	ControlsManager.rebind(_capturing_action, ev.physical_keycode)
	_capture_button.text = ControlsManager.get_current_key_text(_capturing_action)
	_clear_capture()
	get_viewport().set_input_as_handled()


func _clear_capture() -> void:
	_capturing_action = ""
	_capture_button = null
