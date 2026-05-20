extends CanvasLayer
## Vendor screen. Listens for any merchant in the "merchant" group to emit
## opened(self), then displays that merchant's stock with buy buttons.
## Press Esc to close.

@onready var root: Control = $Root
@onready var dim: ColorRect = $Root/Dim
@onready var title_label: Label = $Root/Panel/Margin/VBox/Title
@onready var gold_label: Label = $Root/Panel/Margin/VBox/HeaderRow/GoldLabel
@onready var stock_grid: VBoxContainer = $Root/Panel/Margin/VBox/StockGrid
@onready var close_button: Button = $Root/Panel/Margin/VBox/CloseButton
@onready var tooltip: PanelContainer = $Root/Tooltip
@onready var tooltip_label: RichTextLabel = $Root/Tooltip/Margin/Label

var _player: PlayerController
var _inventory: Inventory
var _merchant: Node


func _ready() -> void:
	root.visible = false
	tooltip.visible = false
	close_button.pressed.connect(close)
	await get_tree().process_frame
	_bind_player()
	_subscribe_merchants()


func _bind_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]
		_inventory = _player.get_node_or_null("Inventory")


func _subscribe_merchants() -> void:
	for m in get_tree().get_nodes_in_group("merchant"):
		if m.has_signal("opened") and not m.opened.is_connected(open):
			m.opened.connect(open)


func open(merchant: Node) -> void:
	_merchant = merchant
	root.visible = true
	get_tree().paused = false  # don't pause; player can leave by walking away
	title_label.text = merchant.merchant_name if "merchant_name" in merchant else "Trader"
	_refresh()


func close() -> void:
	root.visible = false
	tooltip.visible = false
	_merchant = null


func _unhandled_input(event: InputEvent) -> void:
	if root.visible and event is InputEventKey and event.pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			close()


func _process(_delta: float) -> void:
	if tooltip.visible:
		_position_tooltip()
	# Subscribe to any newly-spawned merchants (HubTown is static, but safe)
	if root.visible and _player and _player.stats:
		gold_label.text = "Gold: %d" % _player.stats.gold


func _refresh() -> void:
	for c in stock_grid.get_children():
		c.queue_free()
	if _merchant == null:
		return
	if _player and _player.stats:
		gold_label.text = "Gold: %d" % _player.stats.gold
	for item in _merchant.stock:
		stock_grid.add_child(_make_stock_row(item))


func _make_stock_row(item: Item) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 44)

	var name_btn := Button.new()
	name_btn.custom_minimum_size = Vector2(280, 40)
	name_btn.text = item.display_name
	name_btn.add_theme_color_override("font_color", item.get_rarity_color())
	name_btn.mouse_entered.connect(_show_tooltip.bind(item))
	name_btn.mouse_exited.connect(_hide_tooltip)
	name_btn.pressed.connect(_buy.bind(item))
	row.add_child(name_btn)

	var price_label := Label.new()
	price_label.custom_minimum_size = Vector2(110, 40)
	price_label.text = "%d g" % _price_for(item)
	price_label.add_theme_font_size_override("font_size", 18)
	price_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(price_label)

	return row


func _price_for(item: Item) -> int:
	# Buy = ~4x the item's sell value
	return max(1, item.sell_value * 4)


func _buy(item: Item) -> void:
	if _player == null or _inventory == null:
		return
	var price := _price_for(item)
	if _player.stats.gold < price:
		EventBus.show_floating_text.emit("Not enough gold", _player.global_position + Vector3(0, 2, 0), Color(1, 0.4, 0.3))
		return
	if not _inventory.spend_gold(price):
		return
	if _inventory.add_item(item):
		_merchant.remove_item(item)
		_refresh()


func _show_tooltip(item: Item) -> void:
	tooltip.visible = true
	tooltip_label.clear()
	tooltip_label.push_color(item.get_rarity_color())
	tooltip_label.add_text(item.display_name)
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
	if item.description != "":
		tooltip_label.newline()
		tooltip_label.push_color(Color(0.65, 0.65, 0.7))
		tooltip_label.push_italics()
		tooltip_label.add_text(item.description)
		tooltip_label.pop()
		tooltip_label.pop()


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
