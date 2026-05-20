class_name AchievementDatabase
extends RefCounted
## Static catalog of achievements. AchievementManager tracks counters and
## unlocks. Unlocks persist in user://achievements.json (cross-character).

const ACHIEVEMENTS: Dictionary = {
	# --- Combat milestones ---
	"first_blood": {
		"name": "First Blood",
		"description": "Defeat your first enemy.",
	},
	"veteran": {
		"name": "Veteran",
		"description": "Defeat 100 enemies.",
	},
	"exterminator": {
		"name": "Exterminator",
		"description": "Defeat 500 enemies.",
	},
	# --- Boss kills ---
	"first_boss": {
		"name": "Throneslayer",
		"description": "Defeat your first dungeon boss.",
	},
	"boss_hunter": {
		"name": "Boss Hunter",
		"description": "Defeat 5 dungeon bosses.",
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
