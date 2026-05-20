class_name AoEEffect
extends Node3D
## Reusable AoE skill spawn: a flat visual disk + a HitBox that pulses once.
## Used by Earthquake. Configurable color, radius, damage, expansion curve.

@export var radius: float = 4.0
@export var damage: float = 20.0
@export var hitbox_active_duration: float = 0.18
@export var visual_duration: float = 0.6
@export var color: Color = Color(1.0, 0.5, 0.1, 1.0)

@onready var mesh_instance: MeshInstance3D = $Mesh
@onready var hitbox: HitBox = $HitBox
@onready var hitbox_shape: CollisionShape3D = $HitBox/Shape


func setup(dmg: float, is_crit: bool = false, override_radius: float = -1.0) -> void:
	if override_radius > 0.0:
		radius = override_radius
	damage = dmg
	# Size mesh + collision to match radius
	var mesh := mesh_instance.mesh
	if mesh is CylinderMesh:
		var cyl: CylinderMesh = mesh
		cyl.top_radius = radius
		cyl.bottom_radius = radius
	if hitbox_shape.shape is SphereShape3D:
		(hitbox_shape.shape as SphereShape3D).radius = radius
	# Recolor
	var mat := mesh_instance.get_surface_override_material(0)
	if mat is StandardMaterial3D:
		var sm: StandardMaterial3D = mat
		sm.albedo_color = Color(color.r, color.g, color.b, 0.7)
		sm.emission = color
	# Activate damage
	hitbox.activate(damage, is_crit)
	# Animate the disk: scale from 0 → 1 quickly, then fade
	scale = Vector3(0.05, 1.0, 0.05)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1, 1, 1), 0.18).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_interval(hitbox_active_duration).finished.connect(hitbox.deactivate)
	# Fade out
	if mat is StandardMaterial3D:
		var sm2: StandardMaterial3D = mat
		tween.tween_property(sm2, "albedo_color:a", 0.0, visual_duration - 0.18)
		tween.parallel().tween_property(sm2, "emission_energy_multiplier", 0.0, visual_duration - 0.18)
	tween.tween_callback(queue_free)
