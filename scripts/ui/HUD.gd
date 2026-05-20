extends CanvasLayer
## Phase 1 Week 4 HUD: HP, Mana, XP, Level, skill cooldowns, death overlay.

@onready var hp_bar: ProgressBar = $Root/HPGroup/HPBar
@onready var hp_label: Label = $Root/HPGroup/HPLabel
@onready var mana_bar: ProgressBar = $Root/HPGroup/ManaBar
@onready var mana_label: Label = $Root/HPGroup/ManaLabel
@onready var xp_bar: ProgressBar = $Root/HPGroup/XPBar
@onready var level_label: Label = $Root/HPGroup/LevelLabel

@onready var combo_label: Label = $Root/ComboLabel
@onready var state_label: Label = $Root/StateLabel
@onready var gold_label: Label = $Root/GoldLabel
@onready var death_overlay: ColorRect = $Root/DeathOverlay
@onready var skill_bar: HBoxContainer = $Root/SkillBar

var _player: PlayerController
var _player_health: Health
var _last_health: float = 0.0
var _flash_tween: Tween
var _skill_slot_nodes: Array = []  # array of {bg, fill, name_label, cd_label, key_label}


func _ready() -> void:
	death_overlay.visible = false
	death_overlay.modulate = Color(1, 1, 1, 0)
	await get_tree().process_frame
	_bind_to_player()
	_build_skill_slots()
	EventBus.player_gold_changed.connect(_on_gold_changed)


func _bind_to_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		push_warning("HUD couldn't find player.")
		return
	_player = players[0] as PlayerController
	_player_health = _player.get_node_or_null("Health") as Health
	if _player_health:
		_player_health.health_changed.connect(_on_health_changed)
		_player_health.died.connect(_on_player_died)
		_last_health = _player_health.current_health
		_on_health_changed(_player_health.current_health, _player_health.max_health)


func _build_skill_slots() -> void:
	if _player == null or _player.skill_system == null:
		return
	# Clear existing
	for child in skill_bar.get_children():
		child.queue_free()
	_skill_slot_nodes.clear()

	var skill_ids: Array = _player.skill_system.get_skill_ids()
	var keys := ["Q", "E", "R", "F"]
	for i in range(skill_ids.size()):
		var sid: String = skill_ids[i]
		var def: Dictionary = _player.skill_system.SKILLS[sid]
		var slot := _make_skill_slot(sid, def, keys[i] if i < keys.size() else "?")
		skill_bar.add_child(slot.root)
		_skill_slot_nodes.append(slot)


func _make_skill_slot(skill_id: String, def: Dictionary, key: String) -> Dictionary:
	var root := Panel.new()
	root.custom_minimum_size = Vector2(80, 80)
	var bg := ColorRect.new()
	bg.color = (def.icon_color as Color).darkened(0.4)
	bg.anchors_preset = 15
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = 2
	root.add_child(bg)

	# Cooldown overlay (dark gradient that fills bottom-to-top)
	var cd_overlay := ColorRect.new()
	cd_overlay.color = Color(0, 0, 0, 0.65)
	cd_overlay.anchor_right = 1.0
	cd_overlay.anchor_bottom = 1.0
	cd_overlay.anchor_top = 1.0  # Will scale via anchor_top
	cd_overlay.mouse_filter = 2
	root.add_child(cd_overlay)

	# Skill name
	var name_label := Label.new()
	name_label.text = def.display_name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.position = Vector2(4, 4)
	name_label.size = Vector2(72, 14)
	name_label.mouse_filter = 2
	root.add_child(name_label)

	# Cooldown countdown text
	var cd_label := Label.new()
	cd_label.text = ""
	cd_label.add_theme_font_size_override("font_size", 22)
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_label.anchor_right = 1.0
	cd_label.anchor_bottom = 1.0
	cd_label.add_theme_color_override("font_color", Color(1, 1, 1))
	cd_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	cd_label.add_theme_constant_override("outline_size", 4)
	cd_label.mouse_filter = 2
	root.add_child(cd_label)

	# Key hint
	var key_label := Label.new()
	key_label.text = key
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.position = Vector2(4, 60)
	key_label.modulate = Color(0.85, 0.85, 0.85)
	key_label.mouse_filter = 2
	root.add_child(key_label)

	# Mana cost
	var mana_label_ := Label.new()
	mana_label_.text = "%d MP" % int(def.mana_cost) if "mana_cost" in def else ""
	mana_label_.add_theme_font_size_override("font_size", 11)
	mana_label_.position = Vector2(35, 62)
	mana_label_.modulate = Color(0.55, 0.7, 1)
	mana_label_.mouse_filter = 2
	root.add_child(mana_label_)

	return {
		"root": root,
		"bg": bg,
		"cd_overlay": cd_overlay,
		"cd_label": cd_label,
		"skill_id": skill_id,
	}


func _on_health_changed(current: float, max_value: float) -> void:
	var took_damage := current < _last_health
	_last_health = current
	hp_bar.max_value = max_value
	hp_bar.value = current
	hp_label.text = "%d / %d" % [int(current), int(max_value)]
	if took_damage:
		_flash_hp_bar()


func _flash_hp_bar() -> void:
	if _flash_tween:
		_flash_tween.kill()
	hp_bar.modulate = Color(1.8, 0.45, 0.45)
	_flash_tween = create_tween()
	_flash_tween.tween_property(hp_bar, "modulate", Color.WHITE, 0.4)


func _on_player_died() -> void:
	death_overlay.visible = true
	var tween := create_tween()
	tween.tween_property(death_overlay, "modulate:a", 1.0, 0.8)
	tween.tween_interval(1.5)
	tween.tween_callback(_reload_scene)


func _reload_scene() -> void:
	get_tree().reload_current_scene()


func _on_gold_changed(new_total: int) -> void:
	gold_label.text = "Gold: %d" % new_total


func _process(_delta: float) -> void:
	if _player == null:
		return
	state_label.text = "State: %s" % PlayerController.State.keys()[_player.state]
	combo_label.text = "Combo: %d" % _player.combo_counter if _player.combo_counter > 0 else ""

	# Mana
	if _player.stats:
		var max_m: float = _player.stats.max_mana()
		mana_bar.max_value = max_m
		mana_bar.value = _player.current_mana
		mana_label.text = "%d / %d" % [int(_player.current_mana), int(max_m)]

		# XP
		xp_bar.max_value = float(_player.stats.xp_to_next_level())
		xp_bar.value = float(_player.stats.xp)
		level_label.text = "Lv %d  —  STR %d  AGI %d  INT %d  STA %d" % [
			_player.stats.level,
			_player.stats.strength,
			_player.stats.agility,
			_player.stats.intelligence,
			_player.stats.stamina,
		]

	# Skill cooldowns
	if _player.skill_system:
		for slot in _skill_slot_nodes:
			var cd_remaining: float = _player.skill_system.cooldowns.get(slot.skill_id, 0.0)
			var max_cd: float = _player.skill_system.SKILLS[slot.skill_id].cooldown
			if cd_remaining > 0.0:
				slot.cd_overlay.visible = true
				slot.cd_overlay.anchor_top = 1.0 - (cd_remaining / max_cd)
				slot.cd_overlay.size_flags_vertical = 1
				slot.cd_label.text = "%.1f" % cd_remaining
			else:
				slot.cd_overlay.visible = false
				slot.cd_label.text = ""
