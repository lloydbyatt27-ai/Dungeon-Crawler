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
@onready var quit_hub_button: Button = $Root/MainPanel/Margin/VBox/QuitHubButton
@onready var quit_menu_button: Button = $Root/MainPanel/Margin/VBox/QuitMenuButton

@onready var master_slider: HSlider = $Root/SettingsPanel/Margin/VBox/Master/MasterSlider
@onready var sfx_slider: HSlider = $Root/SettingsPanel/Margin/VBox/SFX/SFXSlider
@onready var music_slider: HSlider = $Root/SettingsPanel/Margin/VBox/Music/MusicSlider
@onready var master_label: Label = $Root/SettingsPanel/Margin/VBox/Master/MasterValue
@onready var sfx_label: Label = $Root/SettingsPanel/Margin/VBox/SFX/SFXValue
@onready var music_label: Label = $Root/SettingsPanel/Margin/VBox/Music/MusicValue
@onready var controls_box: VBoxContainer = $Root/SettingsPanel/Margin/VBox/ControlsBox
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
