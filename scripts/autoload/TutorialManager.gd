extends Node
## First-time-player hints. Tracks which hints have been seen (per install)
## and emits hint_requested as gameplay triggers fire. TutorialOverlay UIs
## listen and display the text. Reset via reset() for testing.

signal hint_requested(text: String)

const FILE_PATH: String = "user://tutorial.json"

const HINTS: Dictionary = {
	"movement":   "WASD to move    ·    Space to dodge",
	"attack":     "Left Mouse: light attack    ·    Right Mouse: heavy",
	"skills":     "Q / E / R cast your class skills (cost mana)",
	"shapeshift": "Press X to enter Changeling Form when Essence is high",
	"inventory":  "Press I to open inventory    ·    Hold Alt to compare items\nPress J for quests, M for the map",
}

var seen: Dictionary = {}
var _dungeon_hint_armed: bool = false


func _ready() -> void:
	_load()
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.player_essence_changed.connect(_on_essence_changed)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.sfx_attack_swing.connect(_on_attack_swing)


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


func _on_item_picked_up(_item) -> void:
	_show("inventory")


# --- Core --------------------------------------------------------

func _show(id: String) -> void:
	if seen.get(id, false):
		return
	seen[id] = true
	_save()
	var text: String = HINTS.get(id, "")
	if text != "":
		hint_requested.emit(text)


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
