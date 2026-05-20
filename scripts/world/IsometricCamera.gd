class_name IsometricCamera
extends Camera3D
## Fixed-angle isometric camera that smoothly follows a target node.
## Designed for Diablo III/IV-style ARPG view: orthographic, ~50deg pitch.
## Assign `target_path` to the player node in the scene.

@export var target_path: NodePath
@export_group("Framing")
@export var pitch_degrees: float = 50.0
@export var yaw_degrees: float = 45.0
@export var distance: float = 18.0
@export var orthographic_size: float = 16.0
@export_group("Follow")
@export var follow_speed: float = 8.0
@export var height_offset: float = 0.0
@export_group("Look-ahead")
@export var lookahead_factor: float = 0.0  # set >0 to push camera toward mouse/aim

var _target: Node3D
var _camera_offset: Vector3

# Screen shake — additive offset that decays each frame.
var _shake_offset: Vector3 = Vector3.ZERO
var _shake_strength: float = 0.0
var _shake_decay: float = 8.0


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = orthographic_size
	EventBus.request_screen_shake.connect(shake)

	# Compute fixed offset from the target along the pitch/yaw vector.
	var pitch := deg_to_rad(pitch_degrees)
	var yaw := deg_to_rad(yaw_degrees)
	# Direction from target to camera (above and behind, rotated by yaw)
	var dir := Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	).normalized()
	_camera_offset = dir * distance + Vector3(0, height_offset, 0)

	if target_path:
		_target = get_node_or_null(target_path)
	if _target == null:
		# Try to find the player automatically
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_target = players[0]

	if _target:
		global_position = _target.global_position + _camera_offset
		look_at(_target.global_position, Vector3.UP)


func _process(delta: float) -> void:
	# Tick down the shake
	if _shake_strength > 0.0:
		_shake_strength = max(0.0, _shake_strength - _shake_decay * delta)
		var s := _shake_strength
		_shake_offset = Vector3(
			randf_range(-s, s),
			randf_range(-s, s) * 0.5,
			randf_range(-s, s)
		)
	else:
		_shake_offset = Vector3.ZERO

	if _target == null:
		return

	var desired := _target.global_position + _camera_offset
	global_position = global_position.lerp(desired, clamp(follow_speed * delta, 0.0, 1.0)) + _shake_offset
	look_at(_target.global_position, Vector3.UP)


func set_target(node: Node3D) -> void:
	_target = node


func shake(strength: float = 0.4, decay: float = 8.0) -> void:
	_shake_strength = max(_shake_strength, strength)
	_shake_decay = decay

