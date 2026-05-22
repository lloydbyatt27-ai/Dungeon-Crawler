extends Node
## Bestiary: records every enemy type the player has slain along with a
## kill counter and the highest max-HP value seen for that type (since
## difficulty + endless scaling makes the same species feel different).
##
## Entry shape:
##   { species_name: { "kills": int, "max_hp_seen": float, "display": String } }
##
## Species key is derived from the enemy node's name — that's the scene
## node name set in the .tscn (e.g. "Goblin", "GoblinChief", "OrcBrute").
## Persisted to user://bestiary.json across runs and characters.

const FILE_PATH: String = "user://bestiary.json"

var entries: Dictionary = {}


func _ready() -> void:
	_load()
	EventBus.enemy_died.connect(_on_enemy_died)


func _on_enemy_died(enemy: Node, _pos: Vector3) -> void:
	if enemy == null:
		return
	var key: String = _species_key(enemy)
	if key == "":
		return
	var entry: Dictionary = entries.get(key, {"kills": 0, "max_hp_seen": 0.0, "display": key})
	entry.kills = int(entry.get("kills", 0)) + 1
	var hp_node = enemy.get_node_or_null("Health")
	if hp_node and "max_health" in hp_node:
		entry.max_hp_seen = max(float(entry.get("max_hp_seen", 0.0)), float(hp_node.max_health))
	entry.display = _display_for(enemy, key)
	entries[key] = entry
	_save()


func _species_key(enemy: Node) -> String:
	# Use the node's name, stripped of any "@N" autorenumber suffix that
	# Godot adds when the same scene is instantiated multiple times.
	var n: String = enemy.name
	var at: int = n.find("@")
	if at >= 0:
		n = n.substr(0, at)
	return n


func _display_for(enemy: Node, fallback: String) -> String:
	if "display_name" in enemy and enemy.display_name != "":
		return enemy.display_name
	# Convert CamelCase node name into spaced label ("OrcBrute" → "Orc Brute")
	var result := ""
	for i in range(fallback.length()):
		var c: String = fallback[i]
		if i > 0 and c == c.to_upper() and c != "_":
			result += " "
		result += c
	return result


func _load() -> void:
	if not FileAccess.file_exists(FILE_PATH):
		return
	var f := FileAccess.open(FILE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		# Defensive load: only accept Dictionary-shaped per-species entries.
		# If a third-party tool or older save format corrupts the file we'd
		# rather drop the bad rows than crash on a later .get() call.
		entries.clear()
		for key in parsed:
			var v = parsed[key]
			if v is Dictionary:
				entries[String(key)] = v.duplicate(true)


func _save() -> void:
	var f := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(entries, "\t"))
	f.close()


func total_kills() -> int:
	var t: int = 0
	for k in entries:
		t += int(entries[k].get("kills", 0))
	return t


func unique_species_count() -> int:
	return entries.size()
