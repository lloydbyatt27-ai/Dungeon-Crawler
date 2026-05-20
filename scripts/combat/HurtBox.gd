class_name HurtBox
extends Area3D
## Damage receiver. Sits on the actor's vulnerable volume.
## When a HitBox finds it, that HitBox calls receive_hit(info) on this node.
## Optionally forwards damage to a Health node and statuses to a
## StatusEffectComponent.

signal hit_received(info: DamageInfo)

@export var health_path: NodePath
@export var status_component_path: NodePath
@export var team: int = 0  # 0 = neutral, 1 = player team, 2 = enemy team

var _health: Health
var _statuses: StatusEffectComponent


func _ready() -> void:
	monitoring = false
	monitorable = true
	if not health_path.is_empty():
		_health = get_node_or_null(health_path) as Health
	if not status_component_path.is_empty():
		_statuses = get_node_or_null(status_component_path) as StatusEffectComponent


func set_status_component(sc: StatusEffectComponent) -> void:
	_statuses = sc


func receive_hit(info: DamageInfo) -> void:
	hit_received.emit(info)
	# Apply statuses BEFORE damage so the freeze tag bumps damage taken
	if _statuses and info.statuses:
		for s in info.statuses:
			_statuses.apply(
				str(s.get("name", "")),
				float(s.get("duration", 0.0)),
				float(s.get("magnitude", 0.0)),
				info.source
			)
	if _health and not _health.is_dead:
		# Freeze tag adds +25 percent damage taken
		if _statuses:
			info.amount *= _statuses.damage_taken_multiplier()
		_health.take_damage(info)
