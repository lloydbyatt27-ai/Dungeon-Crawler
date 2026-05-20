class_name BiomeDatabase
extends RefCounted
## Biome palette presets that tint the dungeon's floor + walls + lights.
## Picked randomly each normal run; cycled every 3 floors in endless mode.

const BIOMES: Array = [
	{
		"name": "Catacombs",
		"floor_tint":     Color(1.0, 1.0, 1.0),    # identity (the default look)
		"wall_tint":      Color(1.0, 1.0, 1.0),
		"light_tint":     Color(1.0, 1.0, 1.0),
		"sun_color":      Color(1.0, 0.93, 0.82),
		"sun_energy":     0.6,
		"enemy_tint":     Color(1.0, 1.0, 1.0),
		"enemy_prefix":   "",  # no prefix in the base biome
	},
	{
		"name": "Crypt",
		"floor_tint":     Color(0.78, 0.85, 1.0),
		"wall_tint":      Color(0.72, 0.82, 0.95),
		"light_tint":     Color(0.55, 0.80, 1.0),
		"sun_color":      Color(0.60, 0.78, 1.0),
		"sun_energy":     0.5,
		"enemy_tint":     Color(0.78, 0.88, 1.0),  # bone-pale
		"enemy_prefix":   "Bone",
	},
	{
		"name": "Swamp",
		"floor_tint":     Color(0.62, 0.80, 0.55),
		"wall_tint":      Color(0.55, 0.72, 0.50),
		"light_tint":     Color(0.70, 1.0, 0.60),
		"sun_color":      Color(0.65, 0.90, 0.55),
		"sun_energy":     0.45,
		"enemy_tint":     Color(0.85, 1.0, 0.65),
		"enemy_prefix":   "Bog",
	},
	{
		"name": "Inferno",
		"floor_tint":     Color(0.85, 0.50, 0.40),
		"wall_tint":      Color(0.65, 0.35, 0.30),
		"light_tint":     Color(1.0,  0.55, 0.25),
		"sun_color":      Color(1.0,  0.50, 0.30),
		"sun_energy":     0.55,
		"enemy_tint":     Color(1.0, 0.60, 0.50),
		"enemy_prefix":   "Hellforged",
	},
]


static func pick_random(rng: RandomNumberGenerator) -> Dictionary:
	return BIOMES[rng.randi() % BIOMES.size()]


## Endless cycle: every 3 floors moves to the next biome (in array order).
static func pick_for_endless_floor(floor_index: int, _rng: RandomNumberGenerator) -> Dictionary:
	if floor_index < 1:
		return BIOMES[0]
	var idx: int = (int((floor_index - 1) / 3)) % BIOMES.size()
	return BIOMES[idx]
