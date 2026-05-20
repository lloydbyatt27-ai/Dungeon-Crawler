extends CanvasLayer
## Phase 1 inventory screen: 3 equipment slots + 24-slot inventory grid.
## Toggle with I. Click an inventory item to equip; click an equipped item to unequip.
## Hover any item for a tooltip.

@onready var root: Control = $Root
@onready var dim: ColorRect = $Root/Dim
@onready var equipment_box: HBoxContainer = $Root/Panel/Margin/VBox/EquipmentBox
@onready var inventory_grid: GridContainer = $Root/Panel/Margin/VBox/InventoryGrid
@onready var gold_label: Label = $Root/Panel/Margin/VBox/HeaderRow/GoldLabel
@onready var tooltip: PanelContainer = $Root/Tooltip
@onready var tooltip_label: RichTextLabel = $Root/Tooltip/Margin/Label

var _player: PlayerController
var _inventory: Inventory
var _hovered_item: Item
var _alt_was_down: bool = false


func _ready() -> void:
	root.visible = false
	tooltip.visible = false
	await get_tree().process_frame
	_bind()


func _bind() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	_player = players[0]
	_inventory = _player.get_node_or_null("Inventory")
	if _inventory:
		_inventory.items_changed.connect(_refresh)
		_inventory.equipment_changed.connect(func(_s, _i): _refresh())
	EventBus.player_gold_changed.connect(_on_gold_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle()
	elif root.visible and event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE and event.pressed:
		toggle()


func toggle() -> void:
	root.visible = not root.visible
	if root.visible:
		_refresh()
	else:
		tooltip.visible = false


func _process(_delta: float) -> void:
	if tooltip.visible:
		var mp := get_viewport().get_mouse_position()
		var cursor_offset := Vector2(18, 18)
		var tip_size := tooltip.size
		var vp := get_viewport().get_visible_rect().size
		var pos := mp + cursor_offset
		if pos.x + tip_size.x > vp.x: pos.x = mp.x - tip_size.x - 8
		if pos.y + tip_size.y > vp.y: pos.y = mp.y - tip_size.y - 8
		tooltip.position = pos
		# Alt toggles equipped-item comparison
		var alt_now := Input.is_key_pressed(KEY_ALT)
		if alt_now != _alt_was_down:
			_alt_was_down = alt_now
			if _hovered_item:
				_show_tooltip(_hovered_item)


func _on_gold_changed(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount


func _refresh() -> void:
	if _inventory == null:
		return
	if _player and _player.stats:
		gold_label.text = "Gold: %d" % _player.stats.gold
	_rebuild_equipment()
	_rebuild_inventory()


func _rebuild_equipment() -> void:
	for c in equipment_box.get_children():
		c.queue_free()
	for slot in Inventory.SLOTS:
		var item: Item = _inventory.equipment[slot]
		var slot_btn := _make_slot_button(item, slot, true)
		equipment_box.add_child(slot_btn)


func _rebuild_inventory() -> void:
	for c in inventory_grid.get_children():
		c.queue_free()
	for item in _inventory.items:
		inventory_grid.add_child(_make_slot_button(item, "", false))
	for _i in range(Inventory.MAX_INVENTORY_SIZE - _inventory.items.size()):
		inventory_grid.add_child(_make_empty_slot())


func _make_slot_button(item, slot_name: String, is_equipped: bool) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(110, 60)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.clip_text = true
	if item == null:
		btn.text = "[ %s ]" % slot_name.capitalize() if is_equipped else ""
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.55, 0.9)
	else:
		btn.text = item.display_name
		btn.add_theme_color_override("font_color", item.get_rarity_color())
		btn.add_theme_color_override("font_hover_color", item.get_rarity_color())
		btn.mouse_entered.connect(_show_tooltip.bind(item))
		btn.mouse_exited.connect(_hide_tooltip)
		if is_equipped:
			btn.pressed.connect(_inventory.unequip.bind(slot_name))
		else:
			btn.pressed.connect(_inventory.equip.bind(item))
	return btn


func _make_empty_slot() -> Control:
	var rect := ColorRect.new()
	rect.color = Color(0.16, 0.16, 0.20, 0.6)
	rect.custom_minimum_size = Vector2(110, 60)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _show_tooltip(item: Item) -> void:
	_hovered_item = item
	tooltip.visible = true
	var equipped: Item = null
	if Input.is_key_pressed(KEY_ALT):
		equipped = ItemTooltip.equipped_for(item, _inventory)
		# Don't compare an item against itself when hovering an equipped slot
		if equipped == item:
			equipped = null
	ItemTooltip.render(tooltip_label, item, equipped)


func _hide_tooltip() -> void:
	tooltip.visible = false
	_hovered_item = null
