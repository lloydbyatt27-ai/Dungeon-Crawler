class_name Health
extends Node
## Reusable HP component. Attach as a child of any actor that can take damage.
## HurtBox forwards damage here; UI and FX listen to the signals.

signal health_changed(current: float, max_value: float)
signal damaged(info: DamageInfo)
signal healed(amount: float)
signal died

@export var max_health: float = 100.0
@export var invulnerable: bool = false
@export_range(0.0, 0.95) var damage_reduction: float = 0.0

var current_health: float = 0.0
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func take_damage(info: DamageInfo) -> void:
	if is_dead or invulnerable or info.amount <= 0:
		return
	# Apply damage reduction (from armor)
	var actual: float = info.amount * (1.0 - damage_reduction)
	# Mutate info so downstream listeners (damage numbers) see the real value
	info.amount = actual
	current_health = max(0.0, current_health - actual)
	damaged.emit(info)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		is_dead = true
		died.emit()


func heal(amount: float) -> void:
	if is_dead or amount <= 0:
		return
	var before := current_health
	current_health = min(max_health, current_health + amount)
	if current_health != before:
		healed.emit(current_health - before)
		health_changed.emit(current_health, max_health)


func set_max_health(new_max: float, refill: bool = false) -> void:
	max_health = new_max
	if refill:
		current_health = max_health
	else:
		current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)


func health_percent() -> float:
	if max_health <= 0:
		return 0.0
	return current_health / max_health
