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
		"form_name": "Earth Titan",
		"form_color": Color(0.55, 0.40, 0.22),
		"form_emission": Color(1.0, 0.55, 0.20),
		"form_scale": 1.45,
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
		"form_name": "Werewolf",
		"form_color": Color(0.35, 0.25, 0.50),
		"form_emission": Color(0.7, 0.3, 1.0),
		"form_scale": 1.30,
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
		"form_name": "Lich",
		"form_color": Color(0.20, 0.30, 0.55),
		"form_emission": Color(0.4, 0.7, 1.0),
		"form_scale": 1.25,
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
		"form_name": "Shadow Demon",
		"form_color": Color(0.30, 0.10, 0.20),
		"form_emission": Color(1.0, 0.10, 0.30),
		"form_scale": 1.30,
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
		"form_name": "Storm Harpy",
		"form_color": Color(0.30, 0.55, 0.45),
		"form_emission": Color(0.6, 1.0, 0.7),
		"form_scale": 1.30,
	},
}


static func get_class_data(class_type: String) -> Dictionary:
	return CLASSES.get(class_type, CLASSES["Guardian"])


static func all_class_names() -> Array:
	return CLASSES.keys()
