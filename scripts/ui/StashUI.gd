extends CanvasLayer
## Stash transfer UI. Left column = player's backpack (deposit here),
## right column = the shared stash (withdraw here). Click an item to
## move it between sides. Stash persists across characters.

@onready var root: Control = $Root
@onready var backpack_grid: VBoxContainer = $Root/Panel/Margin/VBox/Columns/BackpackCol/Grid
@onready var stash_grid: VBoxContainer = $Root/Panel/Margin/VBox/Columns/StashCol/Grid
@onready var backpack_count: Label = $Root/Panel/Margin/VBox/Columns/BackpackCol/Header/CountLabel
@onready var stash_count: Label = $Root/Panel/Margin/VBox/Columns/StashCol/Header/CountLabel
@onready var close_button: Button = $Root/Panel/Margin/VBox/CloseButton
@onready var tooltip: PanelContainer = $Root/Tooltip
@onready var tooltip_label: RichTextLabel = $Root/Tooltip/Margin/Label

var _player: PlayerController
var _inventory: Inventory
var _hovered_item: Item
var _alt_was_down: bool = false


func _ready() -> void:
	root.visible = false
	tooltip.visible = false
	close_button.pressed.connect(close)
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]
		_inventory = _player.get_node_or_null("Inventory")
	for s in get_tree().get_nodes_in_group("stash"):
		if s.has_signal("opened") and not s.opened.is_connected(open):
			s.opened.connect(open)


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
		var alt_now := Input.is_key_pressed(KEY_ALT)
		if alt_now != _alt_was_down:
			_alt_was_down = alt_now
			if _hovered_item:
				_show_tooltip(_hovered_item)


func _refresh() -> void:
	# Backpack column
	for c in backpack_grid.get_children():
		c.queue_free()
	if _inventory:
		for item in _inventory.items:
			backpack_grid.add_child(_make_row(item, true))
		backpack_count.text = "%d / %d" % [_inventory.items.size(), Inventory.MAX_INVENTORY_SIZE]
	# Stash column
	for c in stash_grid.get_children():
		c.queue_free()
	for i in range(SaveSystem.stash.size()):
		var item: Item = SaveSystem.stash[i]
		stash_grid.add_child(_make_row(item, false, i))
	stash_count.text = "%d / %d" % [SaveSystem.stash.size(), SaveSystem.STASH_CAPACITY]


func _make_row(item: Item, in_backpack: bool, stash_index: int = -1) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 36)
	var name_btn := Button.new()
	name_btn.custom_minimum_size = Vector2(240, 32)
	name_btn.text = item.display_with_upgrade()
	name_btn.add_theme_color_override("font_color", item.get_rarity_color())
	name_btn.clip_text = true
	name_btn.mouse_entered.connect(_show_tooltip.bind(item))
	name_btn.mouse_exited.connect(_hide_tooltip)
	if in_backpack:
		name_btn.tooltip_text = "Click to move to stash"
		name_btn.pressed.connect(_deposit.bind(item))
	else:
		name_btn.tooltip_text = "Click to move to backpack"
		name_btn.pressed.connect(_withdraw.bind(stash_index))
	row.add_child(name_btn)
	return row


func _deposit(item: Item) -> void:
	if _inventory == null:
		return
	if SaveSystem.stash.size() >= SaveSystem.STASH_CAPACITY:
		EventBus.show_floating_text.emit("Stash full", _player.global_position + Vector3(0, 2.4, 0), Color(1, 0.4, 0.4))
		return
	if SaveSystem.stash_add(item):
		_inventory.remove_item(item)
		_refresh()


func _withdraw(index: int) -> void:
	if _inventory == null:
		return
	if _inventory.items.size() >= Inventory.MAX_INVENTORY_SIZE:
		EventBus.show_floating_text.emit("Backpack full", _player.global_position + Vector3(0, 2.4, 0), Color(1, 0.4, 0.4))
		return
	var item := SaveSystem.stash_take(index)
	if item:
		_inventory.add_item(item)
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
