extends Node3D
## Visual-only aura that follows a target node for a duration.
## Used by Warcry — pulsing red sphere around the player while buff is active.

@export var follow_path: NodePath
@export var duration: float = 10.0

var _follow: Node3D
var _elapsed: float = 0.0


func _ready() -> void:
	if not follow_path.is_empty():
		_follow = get_node_or_null(follow_path) as Node3D


func setup(follow_target: Node3D, dur: float = 10.0) -> void:
	_follow = follow_target
	duration = dur


func _process(delta: float) -> void:
	_elapsed += delta
	if _follow:
		global_position = _follow.global_position + Vector3(0, 1.0, 0)

	# Pulse scale
	var pulse := 1.0 + 0.08 * sin(_elapsed * 6.0)
	scale = Vector3(pulse, pulse, pulse)

	# Fade out in the last 1 second
	var remaining := duration - _elapsed
	if remaining <= 1.0:
		var mesh_instance := get_node_or_null("Mesh") as MeshInstance3D
		if mesh_instance:
			var mat := mesh_instance.get_surface_override_material(0)
			if mat is StandardMaterial3D:
				(mat as StandardMaterial3D).albedo_color.a = max(0.0, remaining) * 0.35

	if _elapsed >= duration:
		queue_free()
