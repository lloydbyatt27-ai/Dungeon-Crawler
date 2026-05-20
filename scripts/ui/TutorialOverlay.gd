extends CanvasLayer
## Listens to TutorialManager.hint_requested and shows the hint in a panel
## near the top of the screen. Fades in, holds, fades out. Press any key
## to dismiss early.

@onready var root: Control = $Root
@onready var panel: PanelContainer = $Root/Panel
@onready var hint_label: Label = $Root/Panel/Margin/VBox/HintLabel

const FADE_IN: float = 0.35
const HOLD: float = 5.0
const FADE_OUT: float = 0.7

var _active_tween: Tween


func _ready() -> void:
	root.modulate.a = 0.0
	panel.visible = false
	TutorialManager.hint_requested.connect(_on_hint)


func _on_hint(text: String) -> void:
	hint_label.text = text
	panel.visible = true
	root.modulate.a = 0.0
	if _active_tween:
		_active_tween.kill()
	_active_tween = create_tween()
	_active_tween.tween_property(root, "modulate:a", 1.0, FADE_IN)
	_active_tween.tween_interval(HOLD)
	_active_tween.tween_property(root, "modulate:a", 0.0, FADE_OUT)
	_active_tween.tween_callback(_clear)


func _input(event: InputEvent) -> void:
	# Dismiss early on any keyboard/mouse input while the hint is up
	if root.modulate.a > 0.1 and (event is InputEventKey or event is InputEventMouseButton):
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			_dismiss_early()


func _dismiss_early() -> void:
	if _active_tween:
		_active_tween.kill()
	_active_tween = create_tween()
	_active_tween.tween_property(root, "modulate:a", 0.0, 0.25)
	_active_tween.tween_callback(_clear)


func _clear() -> void:
	panel.visible = false
	root.modulate.a = 0.0
