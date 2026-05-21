class_name BossSkeletonKing
extends BaseEnemy
## Phase 2 mechanic: every `summon_interval` seconds, spawns a ring of
## minions around itself. Falls back to standard BaseEnemy AI for melee
## attacks; in phase 2 it also gains super armor (inherited from
## has_enrage_phase) and the summon timer ticks down.

@export var minion_scene: PackedScene
@export var summon_count: int = 3
@export var summon_interval: float = 7.0

var _summon_timer: float = 0.0


func _phase_2_tick(delta: float) -> void:
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = summon_interval
		_spawn_minion_ring()


func _spawn_minion_ring() -> void:
	if minion_scene == null:
		return
	var parent: Node = get_tree().current_scene
	for i in range(summon_count):
		var m: Node = minion_scene.instantiate()
		parent.add_child(m)
		var angle: float = TAU * float(i) / float(summon_count)
		var radius: float = 3.0
		m.global_position = global_position + Vector3(cos(angle) * radius, 0.5, sin(angle) * radius)
		# A bit of a death-puff style spawn burst from the boss
		EventBus.show_floating_text.emit(
			"+",
			m.global_position + Vector3(0, 1.8, 0),
			Color(0.7, 0.7, 1.0)
		)
