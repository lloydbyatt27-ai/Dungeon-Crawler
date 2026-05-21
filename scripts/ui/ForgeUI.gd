extends CanvasLayer
## Forge screen — spend Soul Shards to upgrade inventory items (up to +5)
## and socket gems into empty sockets on rare+ items.

@onready var root: Control = $Root
@onready var shards_label: Label = $Root/Panel/Margin/VBox/HeaderRow/ShardsLabel
@onready var list_box: VBoxContainer = $Root/Panel/Margin/VBox/ItemList
@onready var close_button: Button = $Root/Panel/Margin/VBox/CloseButton
@onready var tooltip: PanelContainer = $Root/Tooltip
@onready var tooltip_label: RichTextLabel = $Root/Tooltip/Margin/Label

var _player: PlayerController
var _inventory: Inventory
var _hovered_item: Item
var _alt_was_down: bool = false

# Gem picker — when set, an overlay panel asks which gem to socket.
var _socket_target: Item = null
var _gem_picker: PanelContainer = null


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
	_close_gem_picker()


func _unhandled_input(event: InputEvent) -> void:
	if root.visible and event is InputEventKey and event.pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			if _gem_picker:
				_close_gem_picker()
			else:
				close()


func _process(_delta: float) -> void:
	if tooltip.visible:
		UIStyle.position_tooltip(tooltip)
		var alt_now := Input.is_key_pressed(KEY_ALT)
		if alt_now != _alt_was_down:
			_alt_was_down = alt_now
			if _hovered_item:
				_show_tooltip(_hovered_item)


func _refresh() -> void:
	if _player and _player.stats:
		shards_label.text = "%d shards" % _player.stats.soul_shards
	for c in list_box.get_children():
		c.queue_free()
	if _inventory == null:
		return
	# Non-gem items first, then gems at the bottom so they're easy to spot.
	var equipment_items: Array = []
	var gem_items: Array = []
	for item in _inventory.items:
		if item.is_gem():
			gem_items.append(item)
		elif item.is_potion():
			continue  # potions aren't forge material
		else:
			equipment_items.append(item)

	if equipment_items.is_empty() and gem_items.is_empty():
		var empty := Label.new()
		empty.text = "Your backpack is empty."
		empty.add_theme_color_override("font_color", UIStyle.COL_MUTED)
		list_box.add_child(empty)
		return

	for item in equipment_items:
		list_box.add_child(_make_row(item))

	if not gem_items.is_empty():
		var divider := Label.new()
		divider.text = "Gems"
		divider.add_theme_font_size_override("font_size", 13)
		divider.add_theme_color_override("font_color", UIStyle.COL_HINT)
		list_box.add_child(divider)
		for gem in gem_items:
			list_box.add_child(_make_gem_row(gem))


func _make_row(item: Item) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 38)

	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(240, 34)
	var label_text := item.display_with_upgrade()
	if item.socket_count > 0:
		label_text += "  " + item.sockets_glyph()
	name_label.text = label_text
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_STOP
	name_label.mouse_entered.connect(_show_tooltip.bind(item))
	name_label.mouse_exited.connect(_hide_tooltip)
	row.add_child(name_label)

	# Upgrade button
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 30)
	if item.upgrade_level >= 5:
		btn.text = "Maxed"
		btn.disabled = true
	else:
		var cost := item.upgrade_cost()
		btn.text = "Upgrade  %d◆" % cost
		btn.add_theme_color_override("font_color", UIStyle.COL_SHARDS)
		if _player == null or _player.stats.soul_shards < cost:
			btn.disabled = true
		btn.pressed.connect(_upgrade.bind(item))
	row.add_child(btn)

	# Reforge button (rare+, gear only; rerolls affixes)
	if int(item.rarity) >= int(Item.Rarity.RARE) and item.get_slot() != "":
		var rf_btn := Button.new()
		rf_btn.custom_minimum_size = Vector2(110, 30)
		var rf_gold: int = _reforge_gold_cost(item)
		var rf_shards: int = _reforge_shard_cost(item)
		rf_btn.text = "Reforge  %dg / %d◆" % [rf_gold, rf_shards]
		rf_btn.add_theme_color_override("font_color", Color(0.95, 0.7, 0.35))
		rf_btn.tooltip_text = "Reroll affixes. Upgrades and socketed gems are lost."
		if _player == null or _player.stats.gold < rf_gold or _player.stats.soul_shards < rf_shards or item.pinned:
			rf_btn.disabled = true
		if item.pinned:
			rf_btn.tooltip_text = "Pinned items can't be reforged. Unpin first (hover and press P)."
		rf_btn.pressed.connect(_reforge.bind(item))
		row.add_child(rf_btn)

	# Socket button (only for items with empty sockets and at least one gem)
	if item.can_socket():
		var socket_btn := Button.new()
		socket_btn.custom_minimum_size = Vector2(80, 30)
		socket_btn.text = "Socket"
		socket_btn.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
		if not _player_has_gem():
			socket_btn.disabled = true
			socket_btn.tooltip_text = "Find a gem first."
		socket_btn.pressed.connect(_begin_socket.bind(item))
		row.add_child(socket_btn)
	return row


func _make_gem_row(gem: Item) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 30)
	var label := Label.new()
	label.custom_minimum_size = Vector2(240, 28)
	label.text = gem.display_name
	label.add_theme_color_override("font_color", gem.get_rarity_color())
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.mouse_entered.connect(_show_tooltip.bind(gem))
	label.mouse_exited.connect(_hide_tooltip)
	row.add_child(label)
	var hint := Label.new()
	hint.text = "(socket via item)"
	hint.add_theme_color_override("font_color", UIStyle.COL_HINT)
	hint.add_theme_font_size_override("font_size", 11)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(hint)
	return row


# --- Upgrade ---------------------------------------------------------

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
		if _inventory:
			_inventory._refresh_stats()
		EventBus.show_floating_text.emit(
			"%s +%d!" % [item.display_name, item.upgrade_level],
			_player.global_position + Vector3(0, 2.4, 0),
			UIStyle.COL_ACCENT
		)
		_refresh()


# --- Reforge ---------------------------------------------------------

func _reforge_gold_cost(item: Item) -> int:
	return 250 * (int(item.rarity) + 1)


func _reforge_shard_cost(item: Item) -> int:
	return 4 * (int(item.rarity) + 1)


func _reforge(item: Item) -> void:
	if item == null or item.pinned or _player == null or _player.stats == null:
		return
	var gold_cost: int = _reforge_gold_cost(item)
	var shard_cost: int = _reforge_shard_cost(item)
	if _player.stats.gold < gold_cost or _player.stats.soul_shards < shard_cost:
		return
	var fresh := ItemDatabase.reforge(item)
	if fresh == null:
		return
	_player.stats.gold -= gold_cost
	_player.stats.soul_shards -= shard_cost
	# Swap in the fresh item. If it was equipped, take the equipped slot too.
	if _inventory.items.has(item):
		var idx: int = _inventory.items.find(item)
		_inventory.items[idx] = fresh
	else:
		# Was it equipped? Replace in the equipment slot.
		for slot in Inventory.SLOTS:
			if _inventory.equipment[slot] == item:
				_inventory.equipment[slot] = fresh
				_inventory.equipment_changed.emit(slot, fresh)
				break
	_inventory._refresh_stats()
	_inventory.items_changed.emit()
	EventBus.player_gold_changed.emit(_player.stats.gold)
	EventBus.player_shards_changed.emit(_player.stats.soul_shards)
	EventBus.player_stats_changed.emit()
	EventBus.show_floating_text.emit(
		"Reforged: " + fresh.display_name,
		_player.global_position + Vector3(0, 2.4, 0),
		Color(0.95, 0.7, 0.35)
	)
	_refresh()


# --- Sockets ---------------------------------------------------------

func _player_has_gem() -> bool:
	if _inventory == null:
		return false
	for it in _inventory.items:
		if it.is_gem():
			return true
	return false


func _begin_socket(item: Item) -> void:
	if not item.can_socket() or not _player_has_gem():
		return
	_socket_target = item
	_show_gem_picker()


func _show_gem_picker() -> void:
	_close_gem_picker()
	_gem_picker = PanelContainer.new()
	_gem_picker.set_anchors_preset(Control.PRESET_CENTER)
	_gem_picker.custom_minimum_size = Vector2(320, 0)
	_gem_picker.position = Vector2(-160, -150)
	root.add_child(_gem_picker)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_gem_picker.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Choose a gem"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", UIStyle.COL_TITLE)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Socketing is permanent."
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", UIStyle.COL_HINT)
	vbox.add_child(subtitle)

	for gem in _inventory.items:
		if not gem.is_gem():
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 28)
		btn.text = gem.display_name
		btn.add_theme_color_override("font_color", gem.get_rarity_color())
		btn.pressed.connect(_apply_gem.bind(gem))
		vbox.add_child(btn)

	var cancel := Button.new()
	cancel.custom_minimum_size = Vector2(0, 28)
	cancel.text = "Cancel"
	cancel.pressed.connect(_close_gem_picker)
	vbox.add_child(cancel)


func _close_gem_picker() -> void:
	if _gem_picker:
		_gem_picker.queue_free()
		_gem_picker = null
	_socket_target = null


func _apply_gem(gem: Item) -> void:
	if _socket_target == null or _inventory == null:
		_close_gem_picker()
		return
	if _socket_target.socket_gem(gem):
		_inventory.remove_item(gem)
		_inventory._refresh_stats()
		EventBus.player_stats_changed.emit()
		EventBus.show_floating_text.emit(
			"Socketed %s" % gem.display_name,
			_player.global_position + Vector3(0, 2.4, 0),
			Color(0.85, 0.75, 0.55)
		)
	_close_gem_picker()
	_refresh()


# --- Tooltip ---------------------------------------------------------

func _show_tooltip(item: Item) -> void:
	_hovered_item = item
	tooltip.visible = true
	var equipped: Item = null
	if Input.is_key_pressed(KEY_ALT):
		equipped = ItemTooltip.equipped_for(item, _inventory)
	ItemTooltip.render(tooltip_label, item, equipped)


func _hide_tooltip() -> void:
	tooltip.visible = false
	_hovered_item = null
