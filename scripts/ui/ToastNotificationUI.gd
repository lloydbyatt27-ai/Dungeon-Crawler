extends CanvasLayer
## Achievement unlock toasts: slide-in panels stacked in the top-right.
## Listens to AchievementManager.achievement_unlocked.

@onready var stack: VBoxContainer = $Root/Stack

const SLIDE_IN_DURATION: float = 0.35
const HOLD_DURATION: float = 4.0
const SLIDE_OUT_DURATION: float = 0.5


func _ready() -> void:
	AchievementManager.achievement_unlocked.connect(_show_toast)


func _show_toast(_id: String, def: Dictionary) -> void:
	if def.is_empty():
		return
	var toast := _build_panel(def)
	stack.add_child(toast)
	# Start hidden + offset to the right
	toast.modulate.a = 0.0
	toast.position.x = 320.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(toast, "modulate:a", 1.0, SLIDE_IN_DURATION)
	tween.tween_property(toast, "position:x", 0.0, SLIDE_IN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(HOLD_DURATION)
	tween.chain().tween_property(toast, "modulate:a", 0.0, SLIDE_OUT_DURATION)
	tween.chain().tween_callback(toast.queue_free)
	# Play the level-up arpeggio as a placeholder until a dedicated SFX is added
	AudioManager.play_sfx(AudioManager.level_up_sfx, 0.6)


func _build_panel(def: Dictionary) -> Control:
	var root := PanelContainer.new()
	root.custom_minimum_size = Vector2(320, 0)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	var header := Label.new()
	header.text = "★ Achievement Unlocked"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35))
	vbox.add_child(header)

	var title := Label.new()
	title.text = String(def.get("name", "?"))
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = String(def.get("description", ""))
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	return root
