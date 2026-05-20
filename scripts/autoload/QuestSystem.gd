extends Node
## Tracks active quests across the game session. Listens to EventBus
## for objective updates and auto-completes when targets are met.
##
## Quests live until completed, and completed_quest_ids on the character
## save prevents repeats per-character.

signal quests_changed
signal quest_completed(quest: Quest)

const MAX_ACTIVE: int = 3

var active_quests: Array[Quest] = []


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.boss_defeated.connect(_on_boss_defeated)


# --- Public API ----------------------------------------------------

func accept(quest_id: String) -> bool:
	if active_quests.size() >= MAX_ACTIVE:
		return false
	if has_active(quest_id):
		return false
	var q := QuestDatabase.create(quest_id)
	if q == null:
		return false
	active_quests.append(q)
	# If the objective is a floor-counter, snap to the player's current floor
	if q.objective_type == "floor" and SaveSystem.endless_mode:
		q.progress = min(q.target, SaveSystem.current_endless_floor)
		_check_complete(q)
	quests_changed.emit()
	return true


func has_active(quest_id: String) -> bool:
	for q in active_quests:
		if q.id == quest_id:
			return true
	return false


func active_ids() -> Array:
	var ids: Array = []
	for q in active_quests:
		ids.append(q.id)
	return ids


func clear_all() -> void:
	active_quests.clear()
	quests_changed.emit()


# --- Persistence ---------------------------------------------------

func serialize() -> Array:
	var out: Array = []
	for q in active_quests:
		out.append({"id": q.id, "progress": q.progress})
	return out


func deserialize(data: Array) -> void:
	active_quests.clear()
	for entry in data:
		if not (entry is Dictionary):
			continue
		var q := QuestDatabase.create(String(entry.get("id", "")))
		if q:
			q.progress = int(entry.get("progress", 0))
			active_quests.append(q)
	quests_changed.emit()


# --- Objective listeners ------------------------------------------

func _on_enemy_died(_enemy: Node, _pos: Vector3) -> void:
	for q in active_quests:
		if q.completed: continue
		if q.objective_type == "kill":
			q.progress += 1
			_check_complete(q)
	quests_changed.emit()


func _on_item_picked_up(item) -> void:
	if item == null:
		return
	for q in active_quests:
		if q.completed: continue
		if q.objective_type == "find_rarity" and int(item.rarity) >= q.target_rarity:
			q.progress += 1
			_check_complete(q)
	quests_changed.emit()


func _on_boss_defeated(_boss: Node) -> void:
	for q in active_quests:
		if q.completed: continue
		if q.objective_type == "boss":
			q.progress += 1
			_check_complete(q)
	# Floor-progress quests also update when bosses fall (since boss = floor cleared)
	if SaveSystem.endless_mode:
		for q in active_quests:
			if q.completed: continue
			if q.objective_type == "floor":
				q.progress = max(q.progress, SaveSystem.current_endless_floor)
				_check_complete(q)
	quests_changed.emit()


# --- Internal -----------------------------------------------------

func _check_complete(q: Quest) -> void:
	if q.progress >= q.target and not q.completed:
		_grant(q)


func _grant(q: Quest) -> void:
	q.completed = true
	# Award the player
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var p = players[0]
		if p.stats:
			p.stats.gold += q.gold_reward
			EventBus.player_gold_changed.emit(p.stats.gold)
			# XP via the existing gain_xp flow so level-ups still fire
			if p.has_method("gain_xp"):
				p.gain_xp(q.xp_reward)
			# Mark as completed on the character's record
			if "completed_quest_ids" in p.stats and not (q.id in p.stats.completed_quest_ids):
				p.stats.completed_quest_ids.append(q.id)
		EventBus.show_floating_text.emit(
			"QUEST: " + q.title,
			p.global_position + Vector3(0, 3.0, 0),
			Color(1, 0.85, 0.4)
		)
	# Drop from active list
	active_quests.erase(q)
	quest_completed.emit(q)
	quests_changed.emit()
