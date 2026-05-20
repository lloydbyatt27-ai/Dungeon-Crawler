extends CanvasLayer
## Vendor screen. Two columns: merchant stock (buy) on the left, player
## inventory (sell + salvage) on the right.

@onready var root: Control = $Root
@onready var dim: ColorRect = $Root/Dim
@onready var title_label: Label = $Root/Panel/Margin/VBox/Title
@onready var gold_label: Label = $Root/Panel/Margin/VBox/HeaderRow/GoldLabel
@onready var shards_label: Label = $Root/Panel/Margin/VBox/HeaderRow/ShardsLabel
@onready var stock_grid: VBoxContainer = $Root/Panel/Margin/VBox/Columns/BuyColumn/StockGrid
@onready var inv_grid: VBoxContainer = $Root/Panel/Margin/VBox/Columns/SellColumn/InvGrid
@onready var close_button: Button = $Root/Panel/Margin/VBox/CloseButton
@onready var tooltip: PanelContainer = $Root/Tooltip
@onready var tooltip_label: RichTextLabel = $Root/Tooltip/Margin/Label

var _player: PlayerController
var _inventory: Inventory
var _merchant: Node
var _hovered_item: Item
var _alt_was_down: bool = false


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
		var alt_now := Input.is_key_pressed(KEY_ALT)
		if alt_now != _alt_was_down:
			_alt_was_down = alt_now
			if _hovered_item:
				_show_tooltip(_hovered_item)


func _refresh() -> void:
	if _merchant == null:
		return
	_update_header()
	_rebuild_buy_column()
	_rebuild_sell_column()


func _update_header() -> void:
	if _player and _player.stats:
		gold_label.text = "%d g" % _player.stats.gold
		shards_label.text = "%d shards" % _player.stats.soul_shards


func _rebuild_buy_column() -> void:
	for c in stock_grid.get_children():
		c.queue_free()
	for item in _merchant.stock:
		stock_grid.add_child(_make_buy_row(item))


func _rebuild_sell_column() -> void:
	for c in inv_grid.get_children():
		c.queue_free()
	if _inventory == null:
		return
	for item in _inventory.items:
		inv_grid.add_child(_make_sell_row(item))


func _make_buy_row(item: Item) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 36)
	var name_btn := Button.new()
	name_btn.custom_minimum_size = Vector2(190, 32)
	name_btn.text = item.display_name
	name_btn.add_theme_color_override("font_color", item.get_rarity_color())
	name_btn.clip_text = true
	name_btn.mouse_entered.connect(_show_tooltip.bind(item))
	name_btn.mouse_exited.connect(_hide_tooltip)
	name_btn.pressed.connect(_buy.bind(item))
	row.add_child(name_btn)
	var price_label := Label.new()
	price_label.custom_minimum_size = Vector2(70, 32)
	price_label.text = "%dg" % _buy_price(item)
	price_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(price_label)
	return row


func _make_sell_row(item: Item) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 36)
	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(150, 32)
	name_label.text = item.display_name
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_STOP
	name_label.mouse_entered.connect(_show_tooltip.bind(item))
	name_label.mouse_exited.connect(_hide_tooltip)
	row.add_child(name_label)

	var sell_btn := Button.new()
	sell_btn.custom_minimum_size = Vector2(64, 32)
	sell_btn.text = "%dg" % item.sell_value
	sell_btn.tooltip_text = "Sell for gold"
	sell_btn.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	sell_btn.pressed.connect(_sell.bind(item))
	row.add_child(sell_btn)

	var salvage_btn := Button.new()
	salvage_btn.custom_minimum_size = Vector2(58, 32)
	salvage_btn.text = "%d◆" % Inventory.SHARD_BY_RARITY.get(item.rarity, 1)
	salvage_btn.tooltip_text = "Salvage for soul shards"
	salvage_btn.add_theme_color_override("font_color", Color(0.8, 0.55, 1))
	salvage_btn.pressed.connect(_salvage.bind(item))
	row.add_child(salvage_btn)
	return row


func _buy_price(item: Item) -> int:
	return max(1, item.sell_value * 4)


func _buy(item: Item) -> void:
	if _player == null or _inventory == null:
		return
	var price := _buy_price(item)
	if _player.stats.gold < price:
		EventBus.show_floating_text.emit("Not enough gold", _player.global_position + Vector3(0, 2, 0), Color(1, 0.4, 0.3))
		return
	if not _inventory.spend_gold(price):
		return
	if _inventory.add_item(item):
		_merchant.remove_item(item)
		_refresh()


func _sell(item: Item) -> void:
	if _inventory == null:
		return
	if _inventory.sell_item(item) > 0:
		_refresh()


func _salvage(item: Item) -> void:
	if _inventory == null:
		return
	if _inventory.salvage_item(item) > 0:
		_refresh()


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


func _position_tooltip() -> void:
	var mp := get_viewport().get_mouse_position()
	var cursor_offset := Vector2(18, 18)
	var tip_size := tooltip.size
	var vp := get_viewport().get_visible_rect().size
	var pos := mp + cursor_offset
	if pos.x + tip_size.x > vp.x: pos.x = mp.x - tip_size.x - 8
	if pos.y + tip_size.y > vp.y: pos.y = mp.y - tip_size.y - 8
	tooltip.position = pos
