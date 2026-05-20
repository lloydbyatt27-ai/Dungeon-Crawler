extends CanvasLayer
## Forge screen — spend Soul Shards to upgrade inventory items (up to +5).
## Each upgrade adds +25% to all of the item's stat bonuses.

@onready var root: Control = $Root
@onready var shards_label: Label = $Root/Panel/Margin/VBox/HeaderRow/ShardsLabel
@onready var list_box: VBoxContainer = $Root/Panel/Margin/VBox/ItemList
@onready var close_button: Button = $Root/Panel/Margin/VBox/CloseButton
@onready var tooltip: PanelContainer = $Root/Tooltip
@onready var tooltip_label: RichTextLabel = $Root/Tooltip/Margin/Label

var _player: PlayerController
var _inventory: Inventory


func _ready() -> void:
	root.visible = false
	tooltip.visible = false
	close_button.pressed.connect(close)
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]
		_inventory = _player.get_node_or_null("Inventory")
	for f in get_tree().get_nodes_in_group("forge"):
		if f.has_signal("opened") and not f.opened.is_connected(open):
			f.opened.connect(open)


func open() -> void:
	root.visible = true
	_refresh()


func close() -> void:
	root.visible = false
	tooltip.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if root.visible and event is InputEventKey and event.pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			close()


func _process(_delta: float) -> void:
	if tooltip.visible:
		_position_tooltip()


func _refresh() -> void:
	if _player and _player.stats:
		shards_label.text = "%d shards" % _player.stats.soul_shards
	for c in list_box.get_children():
		c.queue_free()
	if _inventory == null:
		return
	if _inventory.items.is_empty():
		var empty := Label.new()
		empty.text = "Your backpack is empty."
		empty.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		list_box.add_child(empty)
		return
	for item in _inventory.items:
		list_box.add_child(_make_row(item))


func _make_row(item: Item) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 38)

	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(280, 34)
	name_label.text = item.display_with_upgrade()
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_STOP
	name_label.mouse_entered.connect(_show_tooltip.bind(item))
	name_label.mouse_exited.connect(_hide_tooltip)
	row.add_child(name_label)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(140, 34)
	if item.upgrade_level >= 5:
		btn.text = "Maxed"
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	else:
		var cost := item.upgrade_cost()
		btn.text = "Upgrade  %d◆" % cost
		btn.add_theme_color_override("font_color", Color(0.8, 0.55, 1))
		if _player == null or _player.stats.soul_shards < cost:
			btn.disabled = true
		btn.pressed.connect(_upgrade.bind(item))
	row.add_child(btn)
	return row


func _upgrade(item: Item) -> void:
	if _player == null or _player.stats == null:
		return
	var cost := item.upgrade_cost()
	if cost < 0 or _player.stats.soul_shards < cost:
		return
	if item.upgrade():
		_player.stats.soul_shards -= cost
		EventBus.player_shards_changed.emit(_player.stats.soul_shards)
		EventBus.player_stats_changed.emit()
		# If the item is equipped, refresh equipment stats
		if _inventory:
			_inventory._refresh_stats()
		EventBus.show_floating_text.emit(
			"%s +%d!" % [item.display_name, item.upgrade_level],
			_player.global_position + Vector3(0, 2.4, 0),
			Color(1, 0.7, 0.3)
		)
		_refresh()


func _show_tooltip(item: Item) -> void:
	tooltip.visible = true
	tooltip_label.clear()
	tooltip_label.push_color(item.get_rarity_color())
	tooltip_label.add_text(item.display_with_upgrade())
	tooltip_label.pop()
	tooltip_label.newline()
	tooltip_label.push_color(Color(0.7, 0.7, 0.75))
	tooltip_label.add_text("%s %s (Lv %d)" % [item.get_rarity_name(), item.type_name(), item.level])
	tooltip_label.pop()
	tooltip_label.newline()
	tooltip_label.add_text("\n")
	if item.weapon_damage > 0:    _stat_line("+%d Weapon Damage" % int(item.weapon_damage), Color(1, 0.85, 0.5))
	if item.armor > 0:            _stat_line("+%d Armor" % int(item.armor), Color(0.7, 0.85, 1))
	if item.max_hp_bonus > 0:     _stat_line("+%d Max HP" % int(item.max_hp_bonus), Color(1, 0.55, 0.55))
	if item.max_mana_bonus > 0:   _stat_line("+%d Max Mana" % int(item.max_mana_bonus), Color(0.55, 0.75, 1))
	if item.strength_bonus > 0:   _stat_line("+%d Strength" % item.strength_bonus, Color(1, 0.7, 0.4))
	if item.agility_bonus > 0:    _stat_line("+%d Agility" % item.agility_bonus, Color(0.5, 1, 0.5))
	if item.intelligence_bonus > 0: _stat_line("+%d Intelligence" % item.intelligence_bonus, Color(0.5, 0.8, 1))
	if item.stamina_bonus > 0:    _stat_line("+%d Stamina" % item.stamina_bonus, Color(1, 0.85, 0.6))
	if item.crit_chance_bonus > 0: _stat_line("+%.0f%% Crit Chance" % (item.crit_chance_bonus * 100), Color(1, 0.9, 0.4))
	if item.crit_damage_bonus > 0: _stat_line("+%.0f%% Crit Damage" % (item.crit_damage_bonus * 100), Color(1, 0.6, 0.3))


func _stat_line(text: String, color: Color) -> void:
	tooltip_label.push_color(color)
	tooltip_label.add_text(text)
	tooltip_label.pop()
	tooltip_label.newline()


func _hide_tooltip() -> void:
	tooltip.visible = false


func _position_tooltip() -> void:
	var mp := get_viewport().get_mouse_position()
	var cursor_offset := Vector2(18, 18)
	var tip_size := tooltip.size
	var vp := get_viewport().get_visible_rect().size
	var pos := mp + cursor_offset
	if pos.x + tip_size.x > vp.x: pos.x = mp.x - tip_size.x - 8
	if pos.y + tip_size.y > vp.y: pos.y = mp.y - tip_size.y - 8
	tooltip.position = pos
