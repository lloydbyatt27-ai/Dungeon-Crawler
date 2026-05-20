class_name ClassDatabase
extends RefCounted
## Static catalog of character class definitions.
## Each class has starting attributes, a primary attribute, an auto-allocate
## pattern for per-level stat growth, a body tint, a small description, and
## the three skill IDs the class spawns with.

const CLASSES: Dictionary = {
	"Guardian": {
		"display_name": "Guardian",
		"description": "Front-line tank with heavy armor and devastating melee.",
		"stats": {"strength": 12, "agility": 6, "intelligence": 4, "stamina": 10},
		"auto_allocate": {"strength": 2, "stamina": 1},
		"body_color": Color(0.85, 0.55, 0.30),
		"starter_skills": ["earthquake", "warcry", "frostbite"],
		"primary_attr": "strength",
		"role": "Tank",
		"difficulty": "Easy",
	},
	"Mercenary": {
		"display_name": "Mercenary",
		"description": "Adaptive sellsword. Balanced melee with a touch of magic.",
		"stats": {"strength": 9, "agility": 9, "intelligence": 7, "stamina": 7},
		"auto_allocate": {"strength": 1, "agility": 1, "stamina": 1},
		"body_color": Color(0.55, 0.40, 0.75),
		"starter_skills": ["whirlwind", "battle_trance", "throw_knife"],
		"primary_attr": "strength",
		"role": "Bruiser",
		"difficulty": "Medium",
	},
	"Disciple": {
		"display_name": "Disciple",
		"description": "Mystic monk. Devastating AoE spells, fragile body.",
		"stats": {"strength": 4, "agility": 7, "intelligence": 14, "stamina": 5},
		"auto_allocate": {"intelligence": 2, "stamina": 1},
		"body_color": Color(0.35, 0.60, 1.00),
		"starter_skills": ["fireball", "frost_nova", "mana_shield"],
		"primary_attr": "intelligence",
		"role": "Caster",
		"difficulty": "Hard",
	},
	"Prowler": {
		"display_name": "Prowler",
		"description": "Stealth assassin. Hit-and-run, burst damage from behind.",
		"stats": {"strength": 8, "agility": 14, "intelligence": 5, "stamina": 5},
		"auto_allocate": {"agility": 2, "strength": 1},
		"body_color": Color(0.72, 0.30, 0.30),
		"starter_skills": ["shadow_strike", "frenzy", "bleed_edge"],
		"primary_attr": "agility",
		"role": "Assassin",
		"difficulty": "Hard",
	},
	"Scout": {
		"display_name": "Scout",
		"description": "Ranger and archer. Devastating from afar, fragile up close.",
		"stats": {"strength": 6, "agility": 13, "intelligence": 7, "stamina": 6},
		"auto_allocate": {"agility": 2, "stamina": 1},
		"body_color": Color(0.50, 0.85, 0.45),
		"starter_skills": ["multishot", "eagle_eye", "snipe"],
		"primary_attr": "agility",
		"role": "Ranged DPS",
		"difficulty": "Medium",
	},
}


static func get_class_data(class_type: String) -> Dictionary:
	return CLASSES.get(class_type, CLASSES["Guardian"])


static func all_class_names() -> Array:
	return CLASSES.keys()
