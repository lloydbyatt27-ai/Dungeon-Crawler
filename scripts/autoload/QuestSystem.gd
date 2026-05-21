extends Node
## Tracks active quests across the game session. Listens to EventBus
## for objective updates and auto-completes when targets are met.
##
## Quests live until completed, and completed_quest_ids on the character
## save prevents repeats per-character.

signal quests_changed
signal quest_completed(quest: Quest)

const MAX_ACTIVE: int = 3
const DAILY_REWARD_MULT: float = 3.0
const DAILY_PATH: String = "user://daily.json"
const BOUNTY_SLOTS: int = 3

var active_quests: Array[Quest] = []

# Daily quest — auto-rolled per real-world date, cross-character
var daily_quest: Quest = null
var daily_seed_date: String = ""

# Daily rotating bounty board. 3 ids, refreshed when the calendar day
# changes. Stored on disk alongside the daily quest.
var bounty_ids: Array = []


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	_load_daily()
	_refresh_daily_if_new_day()
	_refresh_bounties_if_new_day()


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
	# Daily quest tracks too
	if daily_quest and not daily_quest.completed and daily_quest.objective_type == "kill":
		daily_quest.progress += 1
		_check_complete_daily()
	quests_changed.emit()


func _on_item_picked_up(item) -> void:
	if item == null:
		return
	for q in active_quests:
		if q.completed: continue
		if q.objective_type == "find_rarity" and int(item.rarity) >= q.target_rarity:
			q.progress += 1
			_check_complete(q)
	if daily_quest and not daily_quest.completed and daily_quest.objective_type == "find_rarity" \
			and int(item.rarity) >= daily_quest.target_rarity:
		daily_quest.progress += 1
		_check_complete_daily()
	quests_changed.emit()


func _on_boss_defeated(_boss: Node) -> void:
	for q in active_quests:
		if q.completed: continue
		if q.objective_type == "boss":
			q.progress += 1
			_check_complete(q)
	if daily_quest and not daily_quest.completed and daily_quest.objective_type == "boss":
		daily_quest.progress += 1
		_check_complete_daily()
	# Floor-progress quests also update when bosses fall (since boss = floor cleared)
	if SaveSystem.endless_mode:
		for q in active_quests:
			if q.completed: continue
			if q.objective_type == "floor":
				q.progress = max(q.progress, SaveSystem.current_endless_floor)
				_check_complete(q)
		if daily_quest and not daily_quest.completed and daily_quest.objective_type == "floor":
			daily_quest.progress = max(daily_quest.progress, SaveSystem.current_endless_floor)
			_check_complete_daily()
	quests_changed.emit()


# --- Internal -----------------------------------------------------

func _check_complete(q: Quest) -> void:
	if q.progress >= q.target and not q.completed:
		_grant(q)


## --- Daily quest -------------------------------------------------

func _refresh_bounties_if_new_day() -> void:
	var today: String = Time.get_date_string_from_system()
	if daily_seed_date == today and not bounty_ids.is_empty():
		return
	# daily_seed_date will be set by _refresh_daily_if_new_day. Use the same.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(today + ":bounties")
	bounty_ids.clear()
	var pool: Array = QuestDatabase.BOUNTY_IDS.duplicate()
	for _i in range(min(BOUNTY_SLOTS, pool.size())):
		var pick: int = rng.randi() % pool.size()
		bounty_ids.append(pool[pick])
		pool.remove_at(pick)
	_save_daily()
	quests_changed.emit()


## Returns the rotating bounty ids that haven't already been accepted or
## completed by this character.
func available_bounties(active_ids: Array, completed_ids: Array) -> Array:
	var result: Array = []
	for id in bounty_ids:
		if id in active_ids or id in completed_ids:
			continue
		result.append(id)
	return result


func _refresh_daily_if_new_day() -> void:
	var today: String = Time.get_date_string_from_system()
	if daily_seed_date == today and daily_quest != null:
		return
	daily_seed_date = today
	# Deterministic by date so all players on the same day see the same daily
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(today)
	var ids: Array = QuestDatabase.all_ids()
	if ids.is_empty():
		daily_quest = null
		_save_daily()
		return
	var template_id: String = ids[rng.randi() % ids.size()]
	daily_quest = QuestDatabase.create(template_id)
	if daily_quest:
		daily_quest.gold_reward = int(daily_quest.gold_reward * DAILY_REWARD_MULT)
		daily_quest.xp_reward = int(daily_quest.xp_reward * DAILY_REWARD_MULT)
		# If it's a floor quest and the player is mid-endless, snap progress
		if daily_quest.objective_type == "floor" and SaveSystem.endless_mode:
			daily_quest.progress = min(daily_quest.target, SaveSystem.current_endless_floor)
	_save_daily()
	quests_changed.emit()


func _check_complete_daily() -> void:
	if daily_quest and daily_quest.progress >= daily_quest.target and not daily_quest.completed:
		_grant_daily()


func _grant_daily() -> void:
	daily_quest.completed = true
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var p = players[0]
		if p.stats:
			p.stats.gold += daily_quest.gold_reward
			EventBus.player_gold_changed.emit(p.stats.gold)
			if p.has_method("gain_xp"):
				p.gain_xp(daily_quest.xp_reward)
		EventBus.show_floating_text.emit(
			"DAILY: " + daily_quest.title,
			p.global_position + Vector3(0, 3.4, 0),
			Color(1, 0.7, 0.3)
		)
	_save_daily()
	quest_completed.emit(daily_quest)
	quests_changed.emit()


func _load_daily() -> void:
	if not FileAccess.file_exists(DAILY_PATH):
		return
	var f := FileAccess.open(DAILY_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return
	daily_seed_date = String(parsed.get("seed_date", ""))
	var b = parsed.get("bounty_ids", [])
	if b is Array:
		bounty_ids = b
	var q_data = parsed.get("quest", null)
	if q_data is Dictionary and q_data.has("id"):
		var template_id: String = String(q_data.id)
		daily_quest = QuestDatabase.create(template_id)
		if daily_quest:
			daily_quest.gold_reward = int(daily_quest.gold_reward * DAILY_REWARD_MULT)
			daily_quest.xp_reward = int(daily_quest.xp_reward * DAILY_REWARD_MULT)
			daily_quest.progress = int(q_data.get("progress", 0))
			daily_quest.completed = bool(q_data.get("completed", false))


func _save_daily() -> void:
	var data: Dictionary = {"seed_date": daily_seed_date, "quest": null, "bounty_ids": bounty_ids}
	if daily_quest:
		data.quest = {
			"id": daily_quest.id,
			"progress": daily_quest.progress,
			"completed": daily_quest.completed,
		}
	var f := FileAccess.open(DAILY_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


# --- Granting -----------------------------------------------------

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
