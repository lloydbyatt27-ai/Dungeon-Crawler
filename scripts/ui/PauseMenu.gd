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
@onready var quit_hub_button: Button = $Root/MainPanel/Margin/VBox/QuitHubButton
@onready var quit_menu_button: Button = $Root/MainPanel/Margin/VBox/QuitMenuButton

@onready var master_slider: HSlider = $Root/SettingsPanel/Margin/VBox/Master/MasterSlider
@onready var sfx_slider: HSlider = $Root/SettingsPanel/Margin/VBox/SFX/SFXSlider
@onready var music_slider: HSlider = $Root/SettingsPanel/Margin/VBox/Music/MusicSlider
@onready var master_label: Label = $Root/SettingsPanel/Margin/VBox/Master/MasterValue
@onready var sfx_label: Label = $Root/SettingsPanel/Margin/VBox/SFX/SFXValue
@onready var music_label: Label = $Root/SettingsPanel/Margin/VBox/Music/MusicValue
@onready var back_button: Button = $Root/SettingsPanel/Margin/VBox/BackButton

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
