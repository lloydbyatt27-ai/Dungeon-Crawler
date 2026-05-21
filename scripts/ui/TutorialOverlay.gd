extends CanvasLayer
## Tutorial hint display. Listens to TutorialManager.hint_requested and
## shows a structured card (icon + title + body + dismiss button). Stays
## visible until the player presses Space or clicks Got It; no auto-fade.

@onready var root: Control = $Root
@onready var panel: PanelContainer = $Root/Panel
@onready var icon_label: Label = $Root/Panel/Margin/VBox/HeaderRow/Icon
@onready var title_label: Label = $Root/Panel/Margin/VBox/HeaderRow/Title
@onready var step_label: Label = $Root/Panel/Margin/VBox/HeaderRow/StepLabel
@onready var hint_label: RichTextLabel = $Root/Panel/Margin/VBox/HintLabel
@onready var dismiss_button: Button = $Root/Panel/Margin/VBox/ButtonRow/DismissButton

var _showing: bool = false


func _ready() -> void:
	root.modulate.a = 0.0
	panel.visible = false
	dismiss_button.pressed.connect(_dismiss)
	TutorialManager.hint_requested.connect(_on_hint)


func _on_hint(payload) -> void:
	# Backward-compat: TutorialManager originally emitted a String.
	# Now it emits a Dictionary {icon, title, body, step}. Accept both.
	var icon: String = "★"
	var title: String = "Tip"
	var body: String = ""
	var step: String = ""
	if payload is Dictionary:
		icon = String(payload.get("icon", icon))
		title = String(payload.get("title", title))
		body = String(payload.get("body", ""))
		step = String(payload.get("step", ""))
	elif payload is String:
		body = String(payload)

	icon_label.text = icon
	title_label.text = title
	step_label.text = step
	hint_label.clear()
	hint_label.append_text(body)
	panel.visible = true
	_showing = true
	var t := create_tween()
	t.tween_property(root, "modulate:a", 1.0, 0.25)


func _input(event: InputEvent) -> void:
	if not _showing:
		return
	if event is InputEventKey and event.pressed:
		var key := (event as InputEventKey).keycode
		if key == KEY_SPACE or key == KEY_ENTER or key == KEY_ESCAPE:
			_dismiss()
			get_viewport().set_input_as_handled()


func _dismiss() -> void:
	if not _showing:
		return
	_showing = false
	var t := create_tween()
	t.tween_property(root, "modulate:a", 0.0, 0.2)
	t.tween_callback(func():
		panel.visible = false
	)
