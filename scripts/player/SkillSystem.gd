class_name SkillSystem
extends Node
## Manages the player's active skills: cooldowns, mana costs, casting, buffs.
## Mapped to skill_1..skill_4 input actions in the order configured below.

@export var earthquake_scene: PackedScene
@export var frostbite_scene: PackedScene
@export var warcry_aura_scene: PackedScene

# Skill definitions — base values; runtime damage applies stat scaling.
const SKILLS: Dictionary = {
	"earthquake": {
		"display_name": "Earthquake",
		"input_action": "skill_1",
		"mana_cost": 25.0,
		"cooldown": 8.0,
		"base_damage": 22.0,
		"str_scaling": 0.6,  # bonus damage per STR point
		"icon_color": Color(1, 0.5, 0.15),
	},
	"warcry": {
		"display_name": "Warcry",
		"input_action": "skill_2",
		"mana_cost": 15.0,
		"cooldown": 18.0,
		"buff_duration": 10.0,
		"damage_bonus": 0.30,  # +30% damage
		"icon_color": Color(1, 0.35, 0.2),
	},
	"frostbite": {
		"display_name": "Frostbite",
		"input_action": "skill_3",
		"mana_cost": 30.0,
		"cooldown": 11.0,
		"base_damage": 16.0,
		"str_scaling": 0.4,
		"icon_color": Color(0.55, 0.9, 1),
	},
}

var cooldowns: Dictionary = {}  # skill_id → seconds remaining
var damage_buff_amount: float = 0.0
var damage_buff_timer: float = 0.0

var _player: PlayerController


func _ready() -> void:
	for skill_id in SKILLS:
		cooldowns[skill_id] = 0.0
	_player = get_parent() as PlayerController


func _process(delta: float) -> void:
	# Tick cooldowns
	for skill_id in cooldowns:
		if cooldowns[skill_id] > 0.0:
			cooldowns[skill_id] = max(0.0, cooldowns[skill_id] - delta)
	# Tick warcry buff
	if damage_buff_timer > 0.0:
		damage_buff_timer -= delta
		if damage_buff_timer <= 0.0:
			damage_buff_amount = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if _player == null or _player.state == _player.State.DEAD:
		return
	for skill_id in SKILLS:
		var action: String = SKILLS[skill_id].input_action
		if event.is_action_pressed(action):
			try_cast(skill_id)


func try_cast(skill_id: String) -> bool:
	if not SKILLS.has(skill_id):
		return false
	var def: Dictionary = SKILLS[skill_id]
	if cooldowns[skill_id] > 0.0:
		return false
	if _player.current_mana < def.mana_cost:
		EventBus.show_floating_text.emit("Not enough mana", _player.global_position, Color(0.6, 0.6, 1))
		return false

	# Pay
	_player.current_mana -= def.mana_cost
	# Apply cooldown reduction (Phase 1: INT-based)
	var cdr: float = _player.stats.cooldown_reduction() if _player.stats else 0.0
	cooldowns[skill_id] = def.cooldown * (1.0 - cdr)

	# Roll crit once for this skill
	var is_crit := false
	if _player.stats:
		is_crit = randf() < _player.stats.crit_chance()

	# Dispatch
	match skill_id:
		"earthquake":  _cast_earthquake(def, is_crit)
		"warcry":      _cast_warcry(def)
		"frostbite":   _cast_frostbite(def, is_crit)

	return true


# --- Individual skill implementations -------------------------------

func _cast_earthquake(def: Dictionary, is_crit: bool) -> void:
	if earthquake_scene == null:
		push_warning("Earthquake scene missing on SkillSystem.")
		return
	var dmg := _scaled_damage(def.base_damage, def.str_scaling, is_crit)
	var fx := earthquake_scene.instantiate() as AoEEffect
	get_tree().current_scene.add_child(fx)
	fx.global_position = _player.global_position
	fx.setup(dmg, is_crit)


func _cast_warcry(def: Dictionary) -> void:
	damage_buff_amount = def.damage_bonus
	damage_buff_timer = def.buff_duration
	if warcry_aura_scene:
		var aura := warcry_aura_scene.instantiate()
		get_tree().current_scene.add_child(aura)
		aura.setup(_player, def.buff_duration)
	EventBus.show_floating_text.emit("WARCRY!", _player.global_position, Color(1, 0.4, 0.2))


func _cast_frostbite(def: Dictionary, is_crit: bool) -> void:
	if frostbite_scene == null:
		push_warning("Frostbite scene missing on SkillSystem.")
		return
	var dmg := _scaled_damage(def.base_damage, def.str_scaling, is_crit)
	var fx := frostbite_scene.instantiate() as ConeEffect
	get_tree().current_scene.add_child(fx)
	fx.global_position = _player.global_position
	fx.rotation.y = _player.rotation.y
	fx.setup(dmg, is_crit)


func _scaled_damage(base: float, str_coef: float, is_crit: bool) -> float:
	var dmg := base
	if _player.stats:
		dmg += float(_player.stats.strength) * str_coef
		dmg *= _player.stats.melee_damage_mult()
	dmg *= (1.0 + damage_buff_amount)
	if is_crit and _player.stats:
		dmg *= _player.stats.crit_damage_mult()
	return dmg


# --- HUD helpers ----------------------------------------------------

func cooldown_ratio(skill_id: String) -> float:
	if not SKILLS.has(skill_id):
		return 0.0
	var max_cd: float = SKILLS[skill_id].cooldown
	if max_cd <= 0:
		return 0.0
	return clamp(cooldowns[skill_id] / max_cd, 0.0, 1.0)


func get_skill_ids() -> Array:
	return SKILLS.keys()
