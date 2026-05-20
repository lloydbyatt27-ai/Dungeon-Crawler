class_name DamageInfo
extends RefCounted
## Lightweight data packet passed from HitBox to HurtBox.
## Carries everything a HurtBox needs to apply damage and feedback.

var amount: float = 0.0
var knockback: float = 0.0
var source: Node = null
var hit_position: Vector3 = Vector3.ZERO
var is_crit: bool = false
var element: String = ""  # "fire", "cold", "shadow", etc. — "" means physical
var stagger: float = 0.0  # seconds to stagger target (0 = no stagger)


static func make(amount_: float, source_: Node = null, hit_pos: Vector3 = Vector3.ZERO) -> DamageInfo:
	var info := DamageInfo.new()
	info.amount = amount_
	info.source = source_
	info.hit_position = hit_pos
	return info
