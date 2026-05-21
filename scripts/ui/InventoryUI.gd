extends CanvasLayer
## Phase 1 inventory screen: 3 equipment slots + 24-slot inventory grid.
## Toggle with I. Click an inventory item to equip; click an equipped item to unequip.
## Hover any item for a tooltip.

@onready var root: Control = $Root
@onready var dim: ColorRect = $Root/Dim
@onready var equipment_box: HBoxContainer = $Root/Panel/Margin/VBox/EquipmentBox
@onready var belt_box: HBoxContainer = $Root/Panel/Margin/VBox/BeltBox
@onready var glyph_box: HBoxContainer = $Root/Panel/Margin/VBox/GlyphBox
@onready var inventory_grid: GridContainer = $Root/Panel/Margin/VBox/InventoryGrid
@onready var stats_grid: GridContainer = $Root/Panel/Margin/VBox/StatsGrid
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
		_inventory.glyphs_changed.connect(_refresh)
	EventBus.player_gold_changed.connect(_on_gold_changed)
	EventBus.player_stats_changed.connect(_rebuild_stats)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle()
	elif root.visible and event is InputEventKey and event.pressed:
		var key := (event as InputEventKey).keycode
		if key == KEY_ESCAPE:
			toggle()
		elif key == KEY_P and _hovered_item:
			_hovered_item.pinned = not _hovered_item.pinned
			_show_tooltip(_hovered_item)
			_refresh()


func toggle() -> void:
	root.visible = not root.visible
	if root.visible:
		_refresh()
	else:
		tooltip.visible = false


func _process(_delta: float) -> void:
	if tooltip.visible:
		UIStyle.position_tooltip(tooltip)
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
	_rebuild_stats()
	_rebuild_equipment()
	_rebuild_belt()
	_rebuild_glyphs()
	_rebuild_inventory()


func _rebuild_stats() -> void:
	for c in stats_grid.get_children():
		c.queue_free()
	if _player == null or _player.stats == null:
		return
	var s: CharacterStats = _player.stats
	# Two columns of (label, value) — GridContainer has 4 cols so each row
	# is two name/value pairs side-by-side
	var pairs: Array = [
		["Level", "%d" % s.level],
		["XP", "%d / %d" % [s.xp, s.xp_to_next_level()]],
		["STR", _attr_text(s.strength, s.bonus_strength)],
		["AGI", _attr_text(s.agility, s.bonus_agility)],
		["INT", _attr_text(s.intelligence, s.bonus_intelligence)],
		["STA", _attr_text(s.stamina, s.bonus_stamina)],
		["Max HP", "%d" % int(s.max_hp())],
		["Max Mana", "%d" % int(s.max_mana())],
		["Melee Dmg", "+%.0f%%" % ((s.melee_damage_mult() - 1.0) * 100)],
		["Ranged Dmg", "+%.0f%%" % ((s.ranged_damage_mult() - 1.0) * 100)],
		["Spell Dmg", "+%.0f%%" % ((s.spell_damage_mult() - 1.0) * 100)],
		["Attack Speed", "+%.0f%%" % ((s.attack_speed_mult() - 1.0) * 100)],
		["Crit Chance", "%.1f%%" % (s.crit_chance() * 100.0)],
		["Crit Damage", "+%.0f%%" % ((s.crit_damage_mult() - 1.0) * 100.0)],
		["Dodge", "%.1f%%" % (s.dodge_chance() * 100.0)],
		["Damage Reduction", "%.1f%%" % (s.damage_reduction() * 100.0)],
		["HP Regen", "%.1f/s" % s.hp_regen_per_sec()],
		["Mana Regen", "%.1f/s" % s.mana_regen_per_sec()],
	]
	for pair in pairs:
		var name_label := Label.new()
		name_label.text = pair[0]
		name_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78))
		name_label.add_theme_font_size_override("font_size", 12)
		stats_grid.add_child(name_label)
		var val_label := Label.new()
		val_label.text = pair[1]
		val_label.add_theme_color_override("font_color", Color(1, 1, 1))
		val_label.add_theme_font_size_override("font_size", 12)
		stats_grid.add_child(val_label)


func _attr_text(base: int, bonus: int) -> String:
	if bonus > 0:
		return "%d  (+%d)" % [base + bonus, bonus]
	if bonus < 0:
		return "%d  (%d)" % [base + bonus, bonus]
	return "%d" % base


func _rebuild_belt() -> void:
	for c in belt_box.get_children():
		c.queue_free()
	for i in range(Inventory.POTION_BELT_SIZE):
		var item: Item = _inventory.potion_belt[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(80, 48)
		btn.clip_text = true
		if item == null:
			btn.text = "[ %d ]" % (i + 1)
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.55, 0.9)
		else:
			btn.text = "%d: %s" % [i + 1, item.display_name]
			btn.add_theme_color_override("font_color", item.get_rarity_color())
			btn.mouse_entered.connect(_show_tooltip.bind(item))
			btn.mouse_exited.connect(_hide_tooltip)
			btn.pressed.connect(_inventory.belt_take.bind(i))
		belt_box.add_child(btn)


func _rebuild_glyphs() -> void:
	for c in glyph_box.get_children():
		c.queue_free()
	for i in range(Inventory.GLYPH_SLOT_COUNT):
		var g: Item = _inventory.glyph_slots[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(120, 46)
		btn.clip_text = true
		if g == null:
			btn.text = "[ Glyph %d ]" % (i + 1)
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.55, 0.9)
		else:
			btn.text = g.display_name
			btn.add_theme_color_override("font_color", g.get_rarity_color())
			btn.mouse_entered.connect(_show_tooltip.bind(g))
			btn.mouse_exited.connect(_hide_tooltip)
			btn.pressed.connect(_inventory.glyph_unequip.bind(i))
		glyph_box.add_child(btn)


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
	# Equipment row has 6 slots so use a narrower width
	if is_equipped:
		btn.custom_minimum_size = Vector2(96, 60)
	else:
		btn.custom_minimum_size = Vector2(110, 56)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.clip_text = true
	if item == null:
		btn.text = "[ %s ]" % slot_name.capitalize() if is_equipped else ""
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.55, 0.9)
	else:
		btn.text = ("• " if item.pinned else "") + item.display_name
		btn.add_theme_color_override("font_color", item.get_rarity_color())
		btn.add_theme_color_override("font_hover_color", item.get_rarity_color())
		btn.mouse_entered.connect(_show_tooltip.bind(item))
		btn.mouse_exited.connect(_hide_tooltip)
		if is_equipped:
			btn.pressed.connect(_inventory.unequip.bind(slot_name))
		elif item.is_gem():
			# Gems aren't equippable — only consumed by the Forge.
			btn.tooltip_text = "Socket me into an item at the Forge."
		elif item.is_potion():
			# Clicking a potion in the backpack sends it to the belt.
			btn.tooltip_text = "Send to potion belt."
			btn.pressed.connect(_inventory.belt_assign.bind(item))
		elif item.is_glyph():
			btn.tooltip_text = "Equip to glyph slot."
			btn.pressed.connect(_inventory.glyph_equip.bind(item))
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
