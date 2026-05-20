class_name AchievementDatabase
extends RefCounted
## Static catalog of achievements. AchievementManager tracks counters and
## unlocks. Unlocks persist in user://achievements.json (cross-character).
## An optional `counter` + `target` pair on an entry enables a progress
## bar in the browser; one-shots just show locked/unlocked.

const ACHIEVEMENTS: Dictionary = {
	# --- Combat milestones ---
	"first_blood": {
		"name": "First Blood",
		"description": "Defeat your first enemy.",
		"counter": "kills", "target": 1,
	},
	"veteran": {
		"name": "Veteran",
		"description": "Defeat 100 enemies.",
		"counter": "kills", "target": 100,
	},
	"exterminator": {
		"name": "Exterminator",
		"description": "Defeat 500 enemies.",
		"counter": "kills", "target": 500,
	},
	# --- Boss kills ---
	"first_boss": {
		"name": "Throneslayer",
		"description": "Defeat your first dungeon boss.",
		"counter": "bosses", "target": 1,
	},
	"boss_hunter": {
		"name": "Boss Hunter",
		"description": "Defeat 5 dungeon bosses.",
		"counter": "bosses", "target": 5,
	},
	"hell_walker": {
		"name": "Hell Walker",
		"description": "Defeat the boss on Hell difficulty.",
	},
	# --- Loot ---
	"collector": {
		"name": "Collector",
		"description": "Find a Rare item or better.",
	},
	"treasure_hoarder": {
		"name": "Treasure Hoarder",
		"description": "Find a Legendary item.",
	},
	"wealthy": {
		"name": "Wealthy",
		"description": "Accumulate 1000 gold.",
	},
	# --- Progression ---
	"forge_master": {
		"name": "Forge Master",
		"description": "Upgrade an item to +5.",
	},
	"shapeshifter": {
		"name": "Shapeshifter",
		"description": "Use Changeling Form 10 times.",
		"counter": "shapeshifts", "target": 10,
	},
	"veteran_descender": {
		"name": "Veteran Descender",
		"description": "Reach Floor 5 in the Endless Descent.",
	},
}


static func get_def(id: String) -> Dictionary:
	return ACHIEVEMENTS.get(id, {})


static func all_ids() -> Array:
	return ACHIEVEMENTS.keys()
