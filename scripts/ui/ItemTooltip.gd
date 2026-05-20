class_name ItemTooltip
extends RefCounted
## Shared tooltip renderer. Pushes formatted text into a RichTextLabel.
## If `equipped` is non-null, each stat line is augmented with a colored
## delta (green for upgrades, red for downgrades) against that equipped item.

const COL_UPGRADE: Color = Color(0.55, 0.85, 0.45)
const COL_DOWNGRADE: Color = Color(0.85, 0.35, 0.35)
const COL_HINT: Color = Color(0.55, 0.55, 0.60)

# Each entry: { prop, label, color, percent? }
const STAT_ROWS: Array = [
	{ "prop": "weapon_damage",      "label": "Weapon Damage", "color": Color(1.0, 0.85, 0.5), "percent": false },
	{ "prop": "armor",              "label": "Armor",         "color": Color(0.7, 0.85, 1.0), "percent": false },
	{ "prop": "max_hp_bonus",       "label": "Max HP",        "color": Color(1.0, 0.55, 0.55), "percent": false },
	{ "prop": "max_mana_bonus",     "label": "Max Mana",      "color": Color(0.55, 0.75, 1.0), "percent": false },
	{ "prop": "strength_bonus",     "label": "Strength",      "color": Color(1.0, 0.70, 0.40), "percent": false },
	{ "prop": "agility_bonus",      "label": "Agility",       "color": Color(0.50, 1.0, 0.50), "percent": false },
	{ "prop": "intelligence_bonus", "label": "Intelligence",  "color": Color(0.50, 0.80, 1.0), "percent": false },
	{ "prop": "stamina_bonus",      "label": "Stamina",       "color": Color(1.0, 0.85, 0.60), "percent": false },
	{ "prop": "crit_chance_bonus",  "label": "Crit Chance",   "color": Color(1.0, 0.90, 0.40), "percent": true  },
	{ "prop": "crit_damage_bonus",  "label": "Crit Damage",   "color": Color(1.0, 0.60, 0.30), "percent": true  },
]


static func render(label: RichTextLabel, item: Item, equipped: Item = null) -> void:
	label.clear()
	# Name
	label.push_color(item.get_rarity_color())
	label.add_text(item.display_with_upgrade())
	label.pop()
	label.newline()
	# Rarity / type / level
	label.push_color(Color(0.7, 0.7, 0.75))
	label.add_text("%s %s (Lv %d)" % [item.get_rarity_name(), item.type_name(), item.level])
	label.pop()
	label.newline()
	label.add_text("\n")
	# Stat rows with optional comparison
	for row in STAT_ROWS:
		_stat_row(label, item, equipped, row)
	# Description
	if item.description != "":
		label.newline()
		label.push_color(Color(0.65, 0.65, 0.7))
		label.push_italics()
		label.add_text(item.description)
		label.pop()
		label.pop()
		label.newline()
	# Compare hint or "nothing equipped"
	if item.get_slot() != "":
		label.newline()
		if equipped == null:
			label.push_color(COL_HINT)
			label.push_italics()
			label.add_text("Hold Alt to compare with equipped")
			label.pop()
			label.pop()
		else:
			label.push_color(COL_HINT)
			label.push_italics()
			label.add_text("Comparing to: %s" % equipped.display_with_upgrade())
			label.pop()
			label.pop()


static func _stat_row(label: RichTextLabel, item: Item, equipped: Item, row: Dictionary) -> void:
	var prop: String = row.prop
	var value: float = float(item.get(prop))
	var eq_value: float = float(equipped.get(prop)) if equipped else 0.0
	# Only show the row if either side has it
	if value <= 0.0 and eq_value <= 0.0:
		return
	var pct: bool = row.get("percent", false)
	var color: Color = row.get("color", Color.WHITE)

	var text: String
	if pct:
		text = "+%.0f%% %s" % [value * 100.0, row.label]
	else:
		text = "+%d %s" % [int(value), row.label]

	label.push_color(color)
	label.add_text(text)
	label.pop()

	if equipped:
		var delta: float = value - eq_value
		if absf(delta) > 0.001:
			var delta_color: Color = COL_UPGRADE if delta > 0 else COL_DOWNGRADE
			var sign: String = "+" if delta > 0 else ""
			var delta_text: String
			if pct:
				delta_text = "  (%s%.0f%%)" % [sign, delta * 100.0]
			else:
				delta_text = "  (%s%d)" % [sign, int(delta)]
			label.push_color(delta_color)
			label.add_text(delta_text)
			label.pop()
	label.newline()


## Look up the player's currently-equipped item in the same slot as `item`,
## for use as the comparison reference. Returns null if no match.
static func equipped_for(item: Item, inventory: Inventory) -> Item:
	if item == null or inventory == null:
		return null
	var slot: String = item.get_slot()
	if slot == "":
		return null
	return inventory.equipment.get(slot)
