class_name ShapeShiftSystem
extends Node
## The Changeling form mechanic. Player accumulates Essence by killing enemies;
## pressing the shapeshift action (X) consumes Essence to enter a powerful
## monster form. While transformed: bigger HP pool, +damage, +DR, +speed,
## skill damage and cooldowns improved. Essence drains over time; dropping
## form triggers a 30 second cooldown before re-entering.

const ACTIVATION_COST: float = 25.0
const DRAIN_PER_SECOND: float = 5.0
const COOLDOWN: float = 30.0
const HP_MULT: float = 2.0
const DAMAGE_MULT: float = 1.75
const SKILL_DAMAGE_MULT: float = 1.5
const SKILL_COOLDOWN_MULT: float = 0.7
const SPEED_MULT: float = 1.20
const DR_BONUS: float = 0.25

signal entered(form_name: String)
signal exited

var is_transformed: bool = false
var cooldown_timer: float = 0.0

var _player: PlayerController
var _original_max_hp: float = 0.0
var _original_move_speed: float = 0.0
var _original_mesh_scale: Vector3 = Vector3.ONE
var _saved_body_material: Material


func _ready() -> void:
	_player = get_parent() as PlayerController


func _process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer = max(0.0, cooldown_timer - delta)

	if is_transformed and _player:
		_player.current_essence = max(0.0, _player.current_essence - DRAIN_PER_SECOND * delta)
		EventBus.player_essence_changed.emit(_player.current_essence)
		if _player.current_essence <= 0.0:
			drop_form()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shapeshift"):
		toggle()


func toggle() -> void:
	if _player == null or _player.state == _player.State.DEAD:
		return
	if is_transformed:
		drop_form()
	elif can_activate():
		activate()
	else:
		if cooldown_timer > 0.0:
			EventBus.show_floating_text.emit(
				"Form on cooldown (%.0fs)" % cooldown_timer,
				_player.global_position + Vector3(0, 2.4, 0),
				Color(0.7, 0.7, 0.9)
			)
		elif _player.current_essence < ACTIVATION_COST:
			EventBus.show_floating_text.emit(
				"Need %d Essence" % int(ACTIVATION_COST),
				_player.global_position + Vector3(0, 2.4, 0),
				Color(0.8, 0.5, 1)
			)


func can_activate() -> bool:
	return (_player.current_essence >= ACTIVATION_COST
		and cooldown_timer <= 0.0
		and not is_transformed)


func activate() -> void:
	if _player == null:
		return
	is_transformed = true
	_player.current_essence -= ACTIVATION_COST
	EventBus.player_essence_changed.emit(_player.current_essence)

	# Boost stats
	_original_max_hp = _player.health.max_health
	_original_move_speed = _player.move_speed
	_player.health.set_max_health(_original_max_hp * HP_MULT, false)
	_player.health.heal(_original_max_hp)  # the bonus HP from the form
	_player.move_speed = _original_move_speed * SPEED_MULT

	# Visuals — scale + recolor + emission
	var class_data: Dictionary = ClassDatabase.get_class_data(_player.stats.class_type)
	var form_color: Color = class_data.get("form_color", Color(0.6, 0.3, 0.6))
	var form_emission: Color = class_data.get("form_emission", Color(1, 0.4, 1))
	var form_scale: float = class_data.get("form_scale", 1.35)

	_original_mesh_scale = _player.body_mesh.scale
	_player.body_mesh.scale = _original_mesh_scale * form_scale

	_saved_body_material = _player.body_mesh.get_surface_override_material(0)
	var form_mat := StandardMaterial3D.new()
	form_mat.albedo_color = form_color
	form_mat.metallic_specular = 0.3
	form_mat.roughness = 0.5
	form_mat.emission_enabled = true
	form_mat.emission = form_emission
	form_mat.emission_energy_multiplier = 1.2
	_player.body_mesh.set_surface_override_material(0, form_mat)
	_player._body_default_material = form_mat

	var form_name: String = class_data.get("form_name", "Changeling")
	EventBus.show_floating_text.emit(
		form_name.to_upper(),
		_player.global_position + Vector3(0, 3.0, 0),
		form_emission
	)
	EventBus.player_shapeshifted.emit(form_name, true)
	entered.emit(form_name)


func drop_form() -> void:
	if not is_transformed or _player == null:
		return
	is_transformed = false
	cooldown_timer = COOLDOWN

	# Restore HP cap (no heal — current HP just clips)
	_player.health.set_max_health(_original_max_hp, false)
	if _player.health.current_health > _original_max_hp:
		_player.health.current_health = _original_max_hp
		_player.health.health_changed.emit(_original_max_hp, _original_max_hp)

	# Restore speed
	_player.move_speed = _original_move_speed

	# Restore visuals
	_player.body_mesh.scale = _original_mesh_scale
	if _saved_body_material:
		_player.body_mesh.set_surface_override_material(0, _saved_body_material)
		_player._body_default_material = _saved_body_material

	EventBus.player_shapeshifted.emit("", false)
	exited.emit()


# --- Multipliers read by combat code while transformed ---------------

func damage_mult() -> float:
	return DAMAGE_MULT if is_transformed else 1.0

func skill_damage_mult() -> float:
	return SKILL_DAMAGE_MULT if is_transformed else 1.0

func skill_cooldown_mult() -> float:
	return SKILL_COOLDOWN_MULT if is_transformed else 1.0

func dr_bonus() -> float:
	return DR_BONUS if is_transformed else 0.0
