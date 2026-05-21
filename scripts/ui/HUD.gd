extends CanvasLayer
## Phase 1 Week 4 HUD: HP, Mana, XP, Level, skill cooldowns, death overlay.

@onready var hp_bar: ProgressBar = $Root/HPGroup/HPBar
@onready var hp_label: Label = $Root/HPGroup/HPLabel
@onready var mana_bar: ProgressBar = $Root/HPGroup/ManaBar
@onready var mana_label: Label = $Root/HPGroup/ManaLabel
@onready var essence_bar: ProgressBar = $Root/HPGroup/EssenceBar
@onready var essence_label: Label = $Root/HPGroup/EssenceLabel
@onready var xp_bar: ProgressBar = $Root/HPGroup/XPBar
@onready var level_label: Label = $Root/HPGroup/LevelLabel

@onready var combo_label: Label = $Root/ComboLabel
@onready var state_label: Label = $Root/StateLabel
@onready var gold_label: Label = $Root/GoldLabel
@onready var difficulty_badge: Label = $Root/DifficultyBadge
@onready var shards_label: Label = $Root/ShardsLabel
@onready var floor_label: Label = $Root/FloorLabel
@onready var form_indicator: Label = $Root/FormIndicator
@onready var death_overlay: ColorRect = $Root/DeathOverlay
@onready var hit_flash: ColorRect = $Root/HitFlash
@onready var death_recap: RichTextLabel = $Root/DeathOverlay/DeathRecap
@onready var skill_bar: HBoxContainer = $Root/SkillBar
@onready var potion_belt: HBoxContainer = $Root/PotionBelt

var _essence_pulse_t: float = 0.0

var _player: PlayerController
var _player_health: Health
var _last_health: float = 0.0
var _flash_tween: Tween
var _skill_slot_nodes: Array = []  # array of {bg, fill, name_label, cd_label, key_label}
var _belt_slot_nodes: Array = []   # one Panel per slot, with a label child


func _ready() -> void:
	death_overlay.visible = false
	death_overlay.modulate = Color(1, 1, 1, 0)
	form_indicator.modulate = Color(1, 1, 1, 0)
	_apply_difficulty_badge()
	await get_tree().process_frame
	_bind_to_player()
	_build_skill_slots()
	_build_belt_slots()
	_refresh_belt()
	EventBus.player_gold_changed.connect(_on_gold_changed)
	EventBus.player_shards_changed.connect(_on_shards_changed)
	EventBus.player_shapeshifted.connect(_on_shapeshifted)
	EventBus.player_dealt_damage.connect(_on_player_dealt_damage)
	EventBus.player_took_damage.connect(_on_player_took_damage)
	# Initial sync with current stats
	if _player and _player.stats:
		shards_label.text = "%d shards" % _player.stats.soul_shards


func _apply_difficulty_badge() -> void:
	var tier: String = SaveSystem.current_run_difficulty
	var data: Dictionary = DifficultyDatabase.get_data(tier)
	difficulty_badge.text = tier
	difficulty_badge.add_theme_color_override("font_color", data.get("color", Color.WHITE))
	# Append HC tag once we have a player reference. The bind happens in
	# _bind_to_player; this re-runs there as well.
	if _player and _player.stats and _player.stats.hardcore:
		difficulty_badge.text = tier + "  ☠ HC"
		difficulty_badge.add_theme_color_override("font_color", Color(1, 0.35, 0.35))
	# Floor / rift indicator (only one is active at a time)
	if SaveSystem.rift_active:
		floor_label.text = "Rift T%d   ·   %s" % [
			SaveSystem.rift_tier,
			_format_rift_time(SaveSystem.rift_time_remaining)
		]
		floor_label.add_theme_color_override("font_color", Color(1, 0.78, 0.35))
	elif SaveSystem.endless_mode:
		floor_label.text = "Floor %d" % SaveSystem.current_endless_floor
	else:
		floor_label.text = ""


static func _format_rift_time(seconds: float) -> String:
	if seconds <= 0.0:
		return "0:00"
	var s: int = int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


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
	if _player.inventory:
		_player.inventory.belt_changed.connect(_refresh_belt)
	# Now that we have a player + stats, re-apply the difficulty badge so the
	# Hardcore tag appears.
	_apply_difficulty_badge()


# --- Potion belt --------------------------------------------------

func _build_belt_slots() -> void:
	for c in potion_belt.get_children():
		c.queue_free()
	_belt_slot_nodes.clear()
	for i in range(Inventory.POTION_BELT_SIZE):
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(46, 46)
		var content_label := Label.new()
		content_label.name = "Content"
		content_label.text = "—"
		content_label.add_theme_font_size_override("font_size", 22)
		content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		content_label.anchor_right = 1.0
		content_label.anchor_bottom = 1.0
		content_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(content_label)
		var key_label := Label.new()
		key_label.name = "Key"
		key_label.text = str(i + 1)
		key_label.add_theme_font_size_override("font_size", 11)
		key_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		key_label.position = Vector2(3, 2)
		key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(key_label)
		potion_belt.add_child(slot)
		_belt_slot_nodes.append({"panel": slot, "content": content_label})


func _refresh_belt() -> void:
	if _player == null or _player.inventory == null:
		return
	for i in range(_belt_slot_nodes.size()):
		var potion: Item = _player.inventory.potion_belt[i]
		var nodes: Dictionary = _belt_slot_nodes[i]
		var content: Label = nodes.content
		if potion == null:
			content.text = "—"
			content.modulate = Color(0.4, 0.4, 0.4)
		else:
			content.text = "♥" if potion.potion_effect == "heal" else "✦"
			content.modulate = Color(1, 0.45, 0.45) if potion.potion_effect == "heal" else Color(0.55, 0.7, 1)


func _build_skill_slots() -> void:
	if _player == null or _player.skill_system == null:
		return
	# Clear existing
	for child in skill_bar.get_children():
		child.queue_free()
	_skill_slot_nodes.clear()

	var skill_ids: Array = _player.skill_system.active_skills
	var keys := ["Q", "E", "R", "F"]
	for i in range(skill_ids.size()):
		var sid: String = skill_ids[i]
		var def: Dictionary = _player.skill_system.SKILL_CATALOG[sid]
		var slot := _make_skill_slot(sid, def, keys[i] if i < keys.size() else "?")
		skill_bar.add_child(slot.root)
		_skill_slot_nodes.append(slot)


func _make_skill_slot(skill_id: String, def: Dictionary, key: String) -> Dictionary:
	var root := Panel.new()
	root.custom_minimum_size = Vector2(80, 80)
	var bg := ColorRect.new()
	bg.color = (def.get("color", Color(0.5, 0.5, 0.5)) as Color).darkened(0.4)
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
	GameState.run_stats.deaths += 1
	# Hardcore: wipe save and stay on the death screen longer so the
	# player processes the permadeath message.
	var is_hardcore: bool = _player and _player.stats and _player.stats.hardcore
	if is_hardcore:
		SaveSystem.delete_save()
		var death_label := death_overlay.get_node_or_null("DeathLabel") as Label
		if death_label:
			death_label.text = "PERMADEATH"
	_build_death_recap()
	var tween := create_tween()
	tween.tween_property(death_overlay, "modulate:a", 1.0, 0.8)
	tween.tween_interval(4.5 if is_hardcore else 3.5)
	tween.tween_callback(_to_main_menu)


func _build_death_recap() -> void:
	if death_recap == null:
		return
	death_recap.clear()
	# Killer attribution
	var killer_name: String = "the dungeon"
	if _player and _player.last_damage_source:
		var src = _player.last_damage_source
		if "display_name" in src and String(src.display_name) != "":
			killer_name = String(src.display_name)
		else:
			killer_name = src.name
	death_recap.push_color(Color(0.85, 0.85, 0.9))
	death_recap.add_text("Slain by ")
	death_recap.push_color(Color(1, 0.55, 0.45))
	death_recap.add_text(killer_name)
	death_recap.pop()
	death_recap.add_text("\n\n")
	# Stats — run deltas from GameState
	var kills: int = int(GameState.run_delta("monsters_killed"))
	var bosses: int = int(GameState.run_delta("bosses_defeated"))
	var gold: int = int(GameState.run_delta("gold_earned_total"))
	var items: int = int(GameState.run_delta("items_collected"))
	var run_time: float = GameState.run_delta("play_time_seconds")
	var time_str: String = "%d:%02d" % [int(run_time) / 60, int(run_time) % 60]
	death_recap.add_text("Run time: %s\n" % time_str)
	death_recap.add_text("Kills: %d   ·   Bosses: %d\n" % [kills, bosses])
	death_recap.add_text("Items collected: %d   ·   Gold gained: %d\n" % [items, gold])
	if _player and _player.stats:
		death_recap.add_text("Final level: %d\n" % _player.stats.level)
	death_recap.pop()


func _to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func _on_gold_changed(new_total: int) -> void:
	gold_label.text = "Gold: %d" % new_total


func _on_shards_changed(new_total: int) -> void:
	shards_label.text = "%d shards" % new_total


func _on_player_dealt_damage(_target, _amount: float, is_crit: bool) -> void:
	# Subtle warm flash on crit only — keeps regular hits noise-free.
	if is_crit:
		_flash_screen(Color(1.0, 0.75, 0.25, 0.22), 0.18)


func _on_player_took_damage(_amount: float, _source) -> void:
	# Red vignette pulse so big incoming hits register even when the HP
	# bar isn't in the player's eye line.
	_flash_screen(Color(1.0, 0.15, 0.15, 0.20), 0.22)


func _flash_screen(c: Color, duration: float) -> void:
	if hit_flash == null:
		return
	hit_flash.color = c
	var t := create_tween()
	t.tween_property(hit_flash, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)


func _on_shapeshifted(form_name: String, is_active: bool) -> void:
	if is_active:
		form_indicator.text = "▼ " + form_name + " ▼"
		var tween := create_tween()
		tween.tween_property(form_indicator, "modulate:a", 1.0, 0.3)
	else:
		var tween := create_tween()
		tween.tween_property(form_indicator, "modulate:a", 0.0, 0.3)


func _process(delta: float) -> void:
	# Rift timer ticks down regardless of player presence
	if SaveSystem.rift_active and SaveSystem.rift_time_remaining > 0.0:
		SaveSystem.rift_time_remaining = max(0.0, SaveSystem.rift_time_remaining - delta)
		# Refresh the rift label every frame so the countdown is smooth
		floor_label.text = "Rift T%d   ·   %s" % [
			SaveSystem.rift_tier,
			_format_rift_time(SaveSystem.rift_time_remaining)
		]
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

		# Essence
		essence_bar.value = _player.current_essence
		essence_label.text = "Essence: %d / 100" % int(_player.current_essence)
		# Pulse the bar when at threshold and not transformed
		if _player.shape_shift and _player.shape_shift.can_activate():
			_essence_pulse_t += delta * 4.0
			var pulse: float = 0.7 + 0.3 * abs(sin(_essence_pulse_t))
			essence_bar.modulate = Color(pulse + 0.2, 0.55 * pulse, 1.0, 1)
		else:
			essence_bar.modulate = Color.WHITE

		# XP — post-cap reads from paragon, pre-cap from the standard bar
		if _player.stats.level >= CharacterStats.LEVEL_CAP:
			xp_bar.max_value = float(_player.stats.xp_to_next_paragon())
			xp_bar.value = float(_player.stats.paragon_xp)
			level_label.text = "Lv %d  P%d  —  STR %d  AGI %d  INT %d  STA %d" % [
				_player.stats.level, _player.stats.paragon_level,
				_player.stats.strength, _player.stats.agility,
				_player.stats.intelligence, _player.stats.stamina,
			]
		else:
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
			var max_cd: float = _player.skill_system.SKILL_CATALOG[slot.skill_id].cooldown
			if cd_remaining > 0.0:
				slot.cd_overlay.visible = true
				slot.cd_overlay.anchor_top = 1.0 - (cd_remaining / max_cd)
				slot.cd_overlay.size_flags_vertical = 1
				slot.cd_label.text = "%.1f" % cd_remaining
			else:
				slot.cd_overlay.visible = false
				slot.cd_label.text = ""
