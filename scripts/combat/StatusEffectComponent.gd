class_name StatusEffectComponent
extends Node
## Manages timed status effects on an enemy. Applied via DamageInfo when a
## HitBox hits a HurtBox; the HurtBox forwards into us.
##
## Effects:
##   "slow"      — movement multiplier (magnitude is the speed scale, e.g. 0.5)
##   "stun"      — cannot act
##   "freeze"    — cannot act + +25 percent damage taken (handled by enemy)
##   "burn"      — tick damage every 1s (magnitude = dmg per tick)
##   "bleed"     — tick damage every 0.5s
##   "poison"    — tick damage every 1s, also reduces healing (unused for now)
##
## Stacking rule (Phase 1): a fresh application of the same effect refreshes
## duration if the new magnitude is >= current, otherwise it's ignored.

signal status_added(effect_name: String)
signal status_removed(effect_name: String)

const DOT_TICK_INTERVALS: Dictionary = {
	"burn":   1.0,
	"bleed":  0.5,
	"poison": 1.0,
}

@export var owner_health_path: NodePath  # the Health node on the owning enemy

var _active: Dictionary = {}  # name → {duration, magnitude, tick_accum, source}
var _health: Health


func _ready() -> void:
	if not owner_health_path.is_empty():
		_health = get_node_or_null(owner_health_path) as Health


func apply(effect_name: String, duration: float, magnitude: float = 0.0, source: Node = null) -> void:
	if duration <= 0.0:
		return
	var existing: Dictionary = _active.get(effect_name, {})
	if not existing.is_empty():
		# Refresh if equal/stronger magnitude or just refresh duration
		if magnitude >= existing.get("magnitude", 0.0):
			existing.magnitude = magnitude
		existing.duration = max(existing.duration, duration)
		return
	_active[effect_name] = {
		"duration": duration,
		"magnitude": magnitude,
		"tick_accum": 0.0,
		"source": source,
	}
	status_added.emit(effect_name)


func clear(effect_name: String) -> void:
	if _active.erase(effect_name):
		status_removed.emit(effect_name)


func clear_all() -> void:
	for k in _active.keys():
		status_removed.emit(k)
	_active.clear()


func has(effect_name: String) -> bool:
	return _active.has(effect_name)


func magnitude(effect_name: String) -> float:
	return _active.get(effect_name, {}).get("magnitude", 0.0)


func is_disabled() -> bool:
	# Returns true if the actor can't act (stun or freeze)
	return _active.has("stun") or _active.has("freeze")


func move_speed_multiplier() -> float:
	if _active.has("freeze") or _active.has("stun"):
		return 0.0
	var slow_mag: float = _active.get("slow", {}).get("magnitude", 1.0)
	if slow_mag <= 0.0:
		slow_mag = 1.0
	return slow_mag


func damage_taken_multiplier() -> float:
	return 1.25 if _active.has("freeze") else 1.0


func _process(delta: float) -> void:
	if _active.is_empty():
		return
	var expired: Array = []
	for name in _active:
		var e: Dictionary = _active[name]
		e.duration -= delta
		if e.duration <= 0.0:
			expired.append(name)
			continue
		# DoT tick
		if DOT_TICK_INTERVALS.has(name) and _health and not _health.is_dead:
			e.tick_accum += delta
			var interval: float = DOT_TICK_INTERVALS[name]
			while e.tick_accum >= interval:
				e.tick_accum -= interval
				_apply_tick(name, e)
	for n in expired:
		_active.erase(n)
		status_removed.emit(n)


func _apply_tick(name: String, e: Dictionary) -> void:
	if _health == null:
		return
	var info := DamageInfo.new()
	info.amount = e.magnitude
	info.source = e.source
	info.element = name
	# DoT can't crit
	info.is_crit = false
	_health.take_damage(info)


func get_active_summary() -> Array:
	return _active.keys()
