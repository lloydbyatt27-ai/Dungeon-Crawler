class_name HitBox
extends Area3D
## Damage dealer. Activated during attack windows.
## Detects HurtBoxes via area_entered and applies damage to them.
## Use `activate()` and `deactivate()` to gate active frames.

signal hit_landed(target: HurtBox, info: DamageInfo)

@export var damage: float = 10.0
@export var knockback: float = 5.0
@export var team: int = 0  # 1 = player attacks, 2 = enemy attacks
@export var source_node_path: NodePath
@export var one_hit_per_target: bool = true
@export var auto_deactivate: bool = false  # for projectiles: stop on first hit
@export var is_crit: bool = false
@export var element: String = ""

# Status effects this hit applies. Each entry: {name, duration, magnitude}.
# Set externally before/at activation; HitBox copies into the DamageInfo.
var apply_statuses: Array = []

var active: bool = false
var _hit_targets: Array[HurtBox] = []
var _source: Node


func _ready() -> void:
	monitoring = false
	monitorable = false
	if not source_node_path.is_empty():
		_source = get_node_or_null(source_node_path)
	else:
		_source = get_parent()
	area_entered.connect(_on_area_entered)


func activate(damage_override: float = -1.0, crit_override: bool = false) -> void:
	active = true
	monitoring = true
	_hit_targets.clear()
	if damage_override > 0.0:
		damage = damage_override
	is_crit = crit_override


func deactivate() -> void:
	active = false
	monitoring = false


func _on_area_entered(area: Area3D) -> void:
	if not active or not (area is HurtBox):
		return
	var hurtbox: HurtBox = area
	if team != 0 and hurtbox.team == team:
		return  # friendly fire off
	if one_hit_per_target and hurtbox in _hit_targets:
		return
	_hit_targets.append(hurtbox)

	var info := DamageInfo.make(damage, _source, global_position)
	info.knockback = knockback
	info.is_crit = is_crit
	info.element = element
	info.statuses = apply_statuses
	hurtbox.receive_hit(info)
	hit_landed.emit(hurtbox, info)
	EventBus.sfx_hit_landed.emit(is_crit)
	# Juice on crits — applies whether it was a player or enemy hit
	if is_crit:
		EventBus.request_screen_shake.emit(0.18, 10.0)
		EventBus.request_hit_stop.emit(0.07)

	if auto_deactivate:
		deactivate()
