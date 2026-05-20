class_name DifficultyDatabase
extends RefCounted
## Difficulty tiers — multipliers applied to enemies and rewards.
## Unlocked tiers persist in SaveSystem; players must clear the boss on a
## tier to unlock the next.

const DIFFICULTIES: Dictionary = {
	"Normal": {
		"display_name": "Normal",
		"description": "Standard run. Recommended for first-time play.",
		"hp_mult": 1.0,
		"damage_mult": 1.0,
		"xp_mult": 1.0,
		"gold_mult": 1.0,
		"essence_mult": 1.0,
		"item_drop_bonus": 0.0,
		"color": Color(0.55, 0.85, 0.45),
	},
	"Hard": {
		"display_name": "Hard",
		"description": "+50% enemy HP, +30% damage. Better loot.",
		"hp_mult": 1.5,
		"damage_mult": 1.3,
		"xp_mult": 1.4,
		"gold_mult": 1.25,
		"essence_mult": 1.2,
		"item_drop_bonus": 0.10,
		"color": Color(1.0, 0.75, 0.35),
	},
	"Hell": {
		"display_name": "Hell",
		"description": "+150% HP, +60% damage. Significantly better drops.",
		"hp_mult": 2.5,
		"damage_mult": 1.6,
		"xp_mult": 2.0,
		"gold_mult": 1.5,
		"essence_mult": 1.4,
		"item_drop_bonus": 0.25,
		"color": Color(1.0, 0.3, 0.25),
	},
}

const TIER_ORDER: Array = ["Normal", "Hard", "Hell"]


static func get_data(tier: String) -> Dictionary:
	return DIFFICULTIES.get(tier, DIFFICULTIES["Normal"])


static func unlock_next_tier(current_tier: String) -> String:
	var idx := TIER_ORDER.find(current_tier)
	if idx == -1 or idx >= TIER_ORDER.size() - 1:
		return ""
	return TIER_ORDER[idx + 1]


static func is_tier_unlocked(tier: String, unlocked_set: Array) -> bool:
	if tier == "Normal":
		return true
	return tier in unlocked_set
