class_name QuestDatabase
extends RefCounted
## Static catalog of available quests. Each template becomes a Quest instance
## via create(id). Filter out completed ones via CharacterStats.completed_quest_ids.

const QUESTS: Dictionary = {
	"slay_ten": {
		"title": "Cull the Vermin",
		"description": "Slay 10 enemies in the dungeons.",
		"objective_type": "kill", "target": 10,
		"gold_reward": 40, "xp_reward": 60,
	},
	"slay_thirty": {
		"title": "Methodical Hunter",
		"description": "Slay 30 enemies across your travels.",
		"objective_type": "kill", "target": 30,
		"gold_reward": 120, "xp_reward": 200,
	},
	"slay_hundred": {
		"title": "Reaper of the Code",
		"description": "Slay 100 enemies. Earn your fame.",
		"objective_type": "kill", "target": 100,
		"gold_reward": 500, "xp_reward": 800,
	},
	"first_blood": {
		"title": "First Blood",
		"description": "Defeat any dungeon boss.",
		"objective_type": "boss", "target": 1,
		"gold_reward": 80, "xp_reward": 150,
	},
	"three_bosses": {
		"title": "Slayer of Tyrants",
		"description": "Defeat three dungeon bosses.",
		"objective_type": "boss", "target": 3,
		"gold_reward": 300, "xp_reward": 500,
	},
	"rare_find": {
		"title": "Treasure Hunter",
		"description": "Find a Rare item or better.",
		"objective_type": "find_rarity", "target": 1, "target_rarity": 2,  # Item.Rarity.RARE
		"gold_reward": 60, "xp_reward": 100,
	},
	"epic_find": {
		"title": "Coveted Trophy",
		"description": "Find an Epic item or better.",
		"objective_type": "find_rarity", "target": 1, "target_rarity": 3,  # Item.Rarity.EPIC
		"gold_reward": 250, "xp_reward": 400,
	},
	"endless_floor_5": {
		"title": "Into the Depths",
		"description": "Reach floor 5 in the Endless Descent.",
		"objective_type": "floor", "target": 5,
		"gold_reward": 200, "xp_reward": 350,
	},
	"endless_floor_10": {
		"title": "Veteran of the Endless",
		"description": "Reach floor 10 in the Endless Descent.",
		"objective_type": "floor", "target": 10,
		"gold_reward": 600, "xp_reward": 1000,
	},
}


static func create(id: String) -> Quest:
	if not QUESTS.has(id):
		return null
	var t: Dictionary = QUESTS[id]
	var q := Quest.new()
	q.id = id
	q.title = t.title
	q.description = t.description
	q.objective_type = t.objective_type
	q.target = int(t.get("target", 1))
	q.target_rarity = int(t.get("target_rarity", 0))
	q.gold_reward = int(t.get("gold_reward", 0))
	q.xp_reward = int(t.get("xp_reward", 0))
	return q


static func all_ids() -> Array:
	return QUESTS.keys()


## Returns up to `count` quest ids that the player can take (not active,
## not already completed). Stable order so the giver doesn't reshuffle
## while the player is mid-decision.
static func available_for(active_ids: Array, completed_ids: Array, count: int = 3) -> Array:
	var result: Array = []
	for id in QUESTS.keys():
		if id in active_ids or id in completed_ids:
			continue
		result.append(id)
		if result.size() >= count:
			break
	return result
