class_name DamageNumber
extends Label3D
## A single floating damage number. Spawned by DamageNumberSpawner.
## Rises, drifts, and fades out, then frees itself.

@export var rise_distance: float = 1.6
@export var drift_distance: float = 0.6
@export var lifetime: float = 0.75

var _elapsed: float = 0.0
var _start_pos: Vector3
var _drift_dir: Vector3


func setup(amount: float, world_pos: Vector3, is_crit: bool = false) -> void:
	text = str(int(round(amount)))
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	fixed_size = true
	render_priority = 10
	outline_size = 8
	if is_crit:
		modulate = Color(1.0, 0.75, 0.25)
		outline_modulate = Color(0.2, 0.1, 0.0)
		pixel_size = 0.012
		text = "%d!" % int(round(amount))
	else:
		modulate = Color(1.0, 1.0, 1.0)
		outline_modulate = Color(0.05, 0.05, 0.05)
		pixel_size = 0.008
	_start_pos = world_pos + Vector3(0, 1.2, 0)
	global_position = _start_pos
	# random horizontal drift to spread overlapping numbers
	_drift_dir = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()


func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = clamp(_elapsed / lifetime, 0.0, 1.0)
	# Ease-out rise
	var rise: float = 1.0 - pow(1.0 - t, 2.0)
	global_position = _start_pos + Vector3.UP * (rise_distance * rise) + _drift_dir * (drift_distance * rise)
	modulate.a = 1.0 - pow(t, 2.0)
	if t >= 1.0:
		queue_free()
