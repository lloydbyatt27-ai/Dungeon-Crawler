class_name HurtBox
extends Area3D
## Damage receiver. Sits on the actor's vulnerable volume.
## When a HitBox finds it, that HitBox calls receive_hit(info) on this node.
## Optionally forwards damage to a Health node.

signal hit_received(info: DamageInfo)

@export var health_path: NodePath
@export var team: int = 0  # 0 = neutral, 1 = player team, 2 = enemy team

var _health: Health


func _ready() -> void:
	monitoring = false  # we don't scan for anything ourselves
	monitorable = true  # but we want to be detected
	if not health_path.is_empty():
		_health = get_node_or_null(health_path) as Health


func receive_hit(info: DamageInfo) -> void:
	hit_received.emit(info)
	if _health and not _health.is_dead:
		_health.take_damage(info)
