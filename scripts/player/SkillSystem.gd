class_name SkillSystem
extends Node
## Holds the master skill catalog (all 15 skills across 5 classes) and casts
## the player's active 3 skills. Buffs are tracked here and read by combat code.
##
## Active skills are configured by PlayerController via set_active_skills()
## using the IDs in CharacterStats' class preset.

@export var aoe_scene: PackedScene
@export var cone_scene: PackedScene
@export var buff_aura_scene: PackedScene
@export var projectile_scene: PackedScene

# Master catalog: every skill known to the game.
# Skill types: "aoe" | "cone" | "buff" | "projectile"
# Buff stats: "damage_bonus" | "attack_speed_bonus" | "crit_chance_bonus" | "damage_reduction_bonus"
const SKILL_CATALOG: Dictionary = {
	# --- Guardian -------------------------------------------------------
	"earthquake": {
		"display_name": "Earthquake", "type": "aoe",
		"mana_cost": 25.0, "cooldown": 8.0,
		"base_damage": 22.0, "scaling_attr": "strength", "scaling_coef": 0.6,
		"radius": 4.0,
		"color": Color(1, 0.5, 0.15),
		"statuses": [{"name": "stun", "duration": 1.2}],
	},
	"warcry": {
		"display_name": "Warcry", "type": "buff",
		"mana_cost": 15.0, "cooldown": 18.0,
		"duration": 10.0, "buff_stat": "damage_bonus", "buff_amount": 0.30,
		"color": Color(1, 0.35, 0.2),
	},
	"frostbite": {
		"display_name": "Frostbite", "type": "cone",
		"mana_cost": 30.0, "cooldown": 11.0,
		"base_damage": 16.0, "scaling_attr": "strength", "scaling_coef": 0.4,
		"color": Color(0.55, 0.9, 1),
		"statuses": [{"name": "slow", "duration": 4.0, "magnitude": 0.5}],
	},

	# --- Mercenary ------------------------------------------------------
	"whirlwind": {
		"display_name": "Whirlwind", "type": "aoe",
		"mana_cost": 22.0, "cooldown": 7.0,
		"base_damage": 18.0, "scaling_attr": "strength", "scaling_coef": 0.5,
		"radius": 3.5,
		"color": Color(0.85, 0.85, 0.95),
	},
	"battle_trance": {
		"display_name": "Battle Trance", "type": "buff",
		"mana_cost": 14.0, "cooldown": 15.0,
		"duration": 8.0, "buff_stat": "attack_speed_bonus", "buff_amount": 0.50,
		"color": Color(1, 0.65, 0.4),
	},
	"throw_knife": {
		"display_name": "Throw Knife", "type": "projectile",
		"mana_cost": 8.0, "cooldown": 2.5,
		"base_damage": 16.0, "scaling_attr": "agility", "scaling_coef": 0.5,
		"speed": 24.0, "radius": 0.3,
		"color": Color(0.9, 0.9, 1.0),
	},

	# --- Disciple -------------------------------------------------------
	"fireball": {
		"display_name": "Fireball", "type": "projectile",
		"mana_cost": 18.0, "cooldown": 3.5,
		"base_damage": 28.0, "scaling_attr": "intelligence", "scaling_coef": 0.9,
		"speed": 16.0, "radius": 0.5,
		"color": Color(1, 0.5, 0.1),
		"statuses": [{"name": "burn", "duration": 5.0, "magnitude": 6.0}],
	},
	"frost_nova": {
		"display_name": "Frost Nova", "type": "aoe",
		"mana_cost": 35.0, "cooldown": 10.0,
		"base_damage": 26.0, "scaling_attr": "intelligence", "scaling_coef": 0.8,
		"radius": 4.5,
		"color": Color(0.5, 0.85, 1.0),
		"statuses": [{"name": "freeze", "duration": 2.0}],
	},
	"mana_shield": {
		"display_name": "Mana Shield", "type": "buff",
		"mana_cost": 20.0, "cooldown": 16.0,
		"duration": 12.0, "buff_stat": "damage_reduction_bonus", "buff_amount": 0.50,
		"color": Color(0.4, 0.6, 1.0),
	},

	# --- Prowler --------------------------------------------------------
	"shadow_strike": {
		"display_name": "Shadow Strike", "type": "aoe",
		"mana_cost": 18.0, "cooldown": 5.0,
		"base_damage": 32.0, "scaling_attr": "agility", "scaling_coef": 0.7,
		"radius": 2.6,
		"color": Color(0.55, 0.30, 0.65),
		"statuses": [{"name": "bleed", "duration": 4.0, "magnitude": 4.0}],
	},
	"frenzy": {
		"display_name": "Frenzy", "type": "buff",
		"mana_cost": 10.0, "cooldown": 12.0,
		"duration": 8.0, "buff_stat": "damage_bonus", "buff_amount": 0.40,
		"color": Color(0.9, 0.2, 0.2),
	},
	"bleed_edge": {
		"display_name": "Bleed Edge", "type": "cone",
		"mana_cost": 22.0, "cooldown": 7.0,
		"base_damage": 20.0, "scaling_attr": "agility", "scaling_coef": 0.5,
		"color": Color(0.85, 0.15, 0.2),
		"statuses": [{"name": "bleed", "duration": 6.0, "magnitude": 5.0}],
	},

	# --- Scout ----------------------------------------------------------
	"multishot": {
		"display_name": "Multishot", "type": "cone",
		"mana_cost": 18.0, "cooldown": 5.0,
		"base_damage": 14.0, "scaling_attr": "agility", "scaling_coef": 0.6,
		"color": Color(0.6, 1.0, 0.5),
	},
	"eagle_eye": {
		"display_name": "Eagle Eye", "type": "buff",
		"mana_cost": 14.0, "cooldown": 20.0,
		"duration": 12.0, "buff_stat": "crit_chance_bonus", "buff_amount": 0.25,
		"color": Color(0.95, 0.85, 0.4),
	},
	"snipe": {
		"display_name": "Snipe", "type": "projectile",
		"mana_cost": 22.0, "cooldown": 6.0,
		"base_damage": 40.0, "scaling_attr": "agility", "scaling_coef": 0.9,
		"speed": 35.0, "radius": 0.35,
		"color": Color(0.55, 0.95, 0.55),
		"statuses": [{"name": "bleed", "duration": 5.0, "magnitude": 8.0}],
	},
}

# Currently equipped skill IDs (3 slots).
var active_skills: Array[String] = []

# Cooldowns per active skill ID.
var cooldowns: Dictionary = {}

# Active timed buffs: stat_name → seconds remaining.
# active_buff_amounts is the live multiplier added on top of base stats.
var active_buff_timers: Dictionary = {}
var active_buff_amounts: Dictionary = {
	"damage_bonus": 0.0,
	"attack_speed_bonus": 0.0,
	"crit_chance_bonus": 0.0,
	"damage_reduction_bonus": 0.0,
}

var _player: PlayerController


func _ready() -> void:
	_player = get_parent() as PlayerController


func set_active_skills(skill_ids: Array) -> void:
	active_skills.clear()
	cooldowns.clear()
	for sid in skill_ids:
		if SKILL_CATALOG.has(sid):
			active_skills.append(sid)
			cooldowns[sid] = 0.0
	EventBus.player_stats_changed.emit()


func _process(delta: float) -> void:
	# Cooldowns
	for sid in cooldowns:
		if cooldowns[sid] > 0.0:
			cooldowns[sid] = max(0.0, cooldowns[sid] - delta)
	# Buff timers
	var expired: Array = []
	for buff_name in active_buff_timers:
		active_buff_timers[buff_name] -= delta
		if active_buff_timers[buff_name] <= 0.0:
			expired.append(buff_name)
	for buff_name in expired:
		active_buff_timers.erase(buff_name)
		active_buff_amounts[buff_name] = 0.0
	# Damage-reduction sync (armor + buffs + form bonus)
	if _player and _player.health:
		var stats_dr := _player.stats.damage_reduction() if _player.stats else 0.0
		var buff_dr: float = active_buff_amounts.get("damage_reduction_bonus", 0.0)
		var form_dr: float = _player.shape_shift.dr_bonus() if _player.shape_shift else 0.0
		_player.health.damage_reduction = min(0.95, stats_dr + buff_dr + form_dr)


func _unhandled_input(event: InputEvent) -> void:
	if _player == null or _player.state == _player.State.DEAD:
		return
	var actions := ["skill_1", "skill_2", "skill_3"]
	for i in range(active_skills.size()):
		if i < actions.size() and event.is_action_pressed(actions[i]):
			try_cast(active_skills[i])


func try_cast(skill_id: String) -> bool:
	if not SKILL_CATALOG.has(skill_id):
		return false
	var def: Dictionary = SKILL_CATALOG[skill_id]
	if cooldowns.get(skill_id, 0.0) > 0.0:
		return false
	var mana_cost: float = def.mana_cost
	if _player.current_mana < mana_cost:
		EventBus.show_floating_text.emit("Not enough mana", _player.global_position, Color(0.6, 0.6, 1))
		return false

	_player.current_mana -= mana_cost
	var cdr: float = _player.stats.cooldown_reduction() if _player.stats else 0.0
	var form_cd_mult: float = _player.shape_shift.skill_cooldown_mult() if _player.shape_shift else 1.0
	cooldowns[skill_id] = def.cooldown * (1.0 - cdr) * form_cd_mult

	var is_crit := false
	if _player.stats:
		is_crit = randf() < (_player.stats.crit_chance() + active_buff_amounts.get("crit_chance_bonus", 0.0))

	match def.type:
		"aoe":        _cast_aoe(def, is_crit)
		"cone":       _cast_cone(def, is_crit)
		"buff":       _cast_buff(def)
		"projectile": _cast_projectile(def, is_crit)
	return true


# --- Cast implementations ------------------------------------------

func _cast_aoe(def: Dictionary, is_crit: bool) -> void:
	if aoe_scene == null: return
	var dmg := _scaled_damage(def, is_crit)
	var fx := aoe_scene.instantiate() as AoEEffect
	get_tree().current_scene.add_child(fx)
	fx.global_position = _player.global_position
	fx.hitbox.apply_statuses = def.get("statuses", [])
	fx.setup(dmg, is_crit, def.get("radius", -1.0), def.color)


func _cast_cone(def: Dictionary, is_crit: bool) -> void:
	if cone_scene == null: return
	var dmg := _scaled_damage(def, is_crit)
	var fx := cone_scene.instantiate() as ConeEffect
	get_tree().current_scene.add_child(fx)
	fx.global_position = _player.global_position
	fx.rotation.y = _player.rotation.y
	fx.hitbox.apply_statuses = def.get("statuses", [])
	fx.setup(dmg, is_crit, def.color)


func _cast_buff(def: Dictionary) -> void:
	var stat_name: String = def.buff_stat
	var amount: float = def.buff_amount
	var duration: float = def.duration
	active_buff_amounts[stat_name] = amount
	active_buff_timers[stat_name] = duration
	if buff_aura_scene:
		var aura := buff_aura_scene.instantiate()
		get_tree().current_scene.add_child(aura)
		aura.setup(_player, duration)
		# Tint the aura by skill color
		var mesh := aura.get_node_or_null("Mesh") as MeshInstance3D
		if mesh:
			var mat := mesh.get_surface_override_material(0)
			if mat is StandardMaterial3D:
				var sm: StandardMaterial3D = mat
				sm.albedo_color = Color(def.color.r, def.color.g, def.color.b, 0.35)
				sm.emission = def.color
	EventBus.show_floating_text.emit(def.display_name.to_upper() + "!", _player.global_position, def.color)


func _cast_projectile(def: Dictionary, is_crit: bool) -> void:
	if projectile_scene == null: return
	var dmg := _scaled_damage(def, is_crit)
	var fx := projectile_scene.instantiate() as ProjectileEffect
	get_tree().current_scene.add_child(fx)
	fx.color = def.color
	fx.speed = def.get("speed", 22.0)
	fx.radius = def.get("radius", 0.4)
	fx.hitbox.apply_statuses = def.get("statuses", [])
	# Player faces local -Z; use the basis to get world forward
	var dir: Vector3 = -_player.global_transform.basis.z
	dir.y = 0.0
	if dir.length() < 0.01:
		dir = Vector3.FORWARD
	fx.setup(dmg, is_crit, dir, _player.global_position)


# --- Damage calc ---------------------------------------------------

func _scaled_damage(def: Dictionary, is_crit: bool) -> float:
	var base: float = def.base_damage
	var dmg := base
	if _player.stats:
		var attr_name: String = def.get("scaling_attr", "strength")
		var coef: float = def.get("scaling_coef", 0.0)
		var attr_value: int = 0
		match attr_name:
			"strength":     attr_value = _player.stats.effective_strength()
			"agility":      attr_value = _player.stats.effective_agility()
			"intelligence": attr_value = _player.stats.effective_intelligence()
			"stamina":      attr_value = _player.stats.effective_stamina()
		dmg += float(attr_value) * coef
		# Use the matching stat-class multiplier
		match attr_name:
			"strength":     dmg *= _player.stats.melee_damage_mult()
			"agility":      dmg *= _player.stats.ranged_damage_mult()
			"intelligence": dmg *= _player.stats.spell_damage_mult()
	dmg *= (1.0 + active_buff_amounts.get("damage_bonus", 0.0))
	if _player.shape_shift:
		dmg *= _player.shape_shift.skill_damage_mult()
	if is_crit and _player.stats:
		dmg *= _player.stats.crit_damage_mult()
	return dmg


# --- Convenience for HUD ----------------------------------------

func cooldown_ratio(skill_id: String) -> float:
	if not SKILL_CATALOG.has(skill_id):
		return 0.0
	var max_cd: float = SKILL_CATALOG[skill_id].cooldown
	if max_cd <= 0.0:
		return 0.0
	return clamp(cooldowns.get(skill_id, 0.0) / max_cd, 0.0, 1.0)


func get_skill_def(skill_id: String) -> Dictionary:
	return SKILL_CATALOG.get(skill_id, {})


# Phase 1 compatibility — PlayerController still reads damage_buff_amount
# directly during melee attacks.
var damage_buff_amount: float:
	get: return active_buff_amounts.get("damage_bonus", 0.0)
