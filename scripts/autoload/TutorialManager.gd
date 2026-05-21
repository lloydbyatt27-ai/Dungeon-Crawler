extends Node
## First-time-player hints. Tracks which hints have been seen (per install)
## and emits hint_requested as gameplay triggers fire. The overlay listens
## for the structured payload {icon, title, body, step}. Reset via reset().

signal hint_requested(payload)

const FILE_PATH: String = "user://tutorial.json"

## Ordered ids drive the "Tip N of M" badge in the overlay.
const HINT_ORDER: Array = [
	"movement", "attack", "skills", "shapeshift",
	"inventory", "potion", "loot", "forge", "stash", "merc",
]

const HINTS: Dictionary = {
	"movement": {
		"icon": "✦", "title": "Movement",
		"body": "[b]WASD[/b] to move    ·    [b]Space[/b] to dodge\nDodging gives brief invulnerability."
	},
	"attack": {
		"icon": "⚔", "title": "Attacks",
		"body": "[b]Left Mouse[/b]: light attack chain\n[b]Right Mouse[/b]: heavy (slower, harder hitting)"
	},
	"skills": {
		"icon": "✺", "title": "Skills",
		"body": "[b]Q / E / R[/b] cast your class skills (cost mana).\nSpend skill points at the PauseMenu > [b]Skills[/b] panel ([b]K[/b])."
	},
	"shapeshift": {
		"icon": "▼", "title": "Shapeshift",
		"body": "Press [b]X[/b] to enter Changeling Form when [color=#cc99ff]Essence[/color] is high.\nForms boost damage and reshape your kit."
	},
	"inventory": {
		"icon": "▣", "title": "Inventory",
		"body": "[b]I[/b] opens inventory · hold [b]Alt[/b] to compare gear · [b]P[/b] pins an item against accidental selling."
	},
	"potion": {
		"icon": "♥", "title": "Potion Belt",
		"body": "Buy potions from the [color=#aaff99]Alchemist[/color]. Drag onto your belt then press [b]1-4[/b] to drink."
	},
	"loot": {
		"icon": "✶", "title": "Loot",
		"body": "Rare items shine with a beam. Walk near them to vacuum drops up.\nFilter what auto-picks via PauseMenu > [b]Loot Filter[/b]."
	},
	"forge": {
		"icon": "⚒", "title": "The Forge",
		"body": "Spend [color=#cc99ff]Soul Shards[/color] to upgrade gear, socket gems, or [b]Reforge[/b] rare+ affixes."
	},
	"stash": {
		"icon": "▤", "title": "The Vault",
		"body": "Stash items across characters. Four tabs (General / Gems / Sets / Dump) keep things organized."
	},
	"merc": {
		"icon": "♟", "title": "Mercenary",
		"body": "Hire an AI follower from PauseMenu > [b]Mercenary[/b]. They level up alongside you."
	},
}

var seen: Dictionary = {}
var _dungeon_hint_armed: bool = false


func _ready() -> void:
	_load()
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.player_essence_changed.connect(_on_essence_changed)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.sfx_attack_swing.connect(_on_attack_swing)
	EventBus.player_gold_changed.connect(_on_gold_changed)


func _process(_delta: float) -> void:
	# Watch for dungeon entry on a poll so we don't depend on signal order
	if not _dungeon_hint_armed and not seen.get("movement", false):
		if get_tree().get_first_node_in_group("dungeon_generator") != null:
			_dungeon_hint_armed = true
			_delayed_show("movement", 1.5)


# --- Event handlers ----------------------------------------------

func _on_attack_swing() -> void:
	_show("attack")


func _on_level_up(_level: int) -> void:
	_show("skills")


func _on_essence_changed(value: float) -> void:
	if value >= 25.0:
		_show("shapeshift")


func _on_item_picked_up(item) -> void:
	_show("inventory")
	# A loot beam hint only really makes sense once you've seen one
	if item and "rarity" in item and int(item.rarity) >= int(Item.Rarity.RARE):
		_show("loot")


func _on_gold_changed(amount: int) -> void:
	# Forge/stash/merc hints kick in once the player has some gold to spend
	if amount >= 200:
		_show("forge")
	if amount >= 500:
		_show("stash")
	if amount >= 400:
		_show("merc")


# --- Core --------------------------------------------------------

func _show(id: String) -> void:
	if seen.get(id, false):
		return
	seen[id] = true
	_save()
	var hint: Dictionary = HINTS.get(id, {})
	if hint.is_empty():
		return
	var step_index: int = HINT_ORDER.find(id) + 1
	var payload := {
		"icon": hint.get("icon", "★"),
		"title": hint.get("title", "Tip"),
		"body": hint.get("body", ""),
		"step": "Tip %d / %d" % [step_index, HINT_ORDER.size()],
	}
	hint_requested.emit(payload)


func _delayed_show(id: String, delay: float) -> void:
	if seen.get(id, false):
		return
	await get_tree().create_timer(delay).timeout
	_show(id)


# --- Persistence -------------------------------------------------

func _load() -> void:
	if not FileAccess.file_exists(FILE_PATH):
		return
	var f := FileAccess.open(FILE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return
	var arr = parsed.get("seen", [])
	if arr is Array:
		for id in arr:
			seen[String(id)] = true


func _save() -> void:
	var data := {"seen": seen.keys()}
	var f := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func reset() -> void:
	seen.clear()
	_dungeon_hint_armed = false
	_save()
