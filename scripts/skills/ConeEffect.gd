class_name ConeEffect
extends Node3D
## Forward-facing cone effect for skills like Frostbite.
## The mesh is a flat triangle/wedge on the ground; the HitBox covers the cone area.

@export var range: float = 5.0
@export var damage: float = 15.0
@export var hitbox_active_duration: float = 0.16
@export var visual_duration: float = 0.55
@export var color: Color = Color(0.4, 0.8, 1.0, 1.0)

@onready var mesh_instance: MeshInstance3D = $Mesh
@onready var hitbox: HitBox = $HitBox


func setup(dmg: float, is_crit: bool = false) -> void:
	damage = dmg
	var mat := mesh_instance.get_surface_override_material(0)
	if mat is StandardMaterial3D:
		var sm: StandardMaterial3D = mat
		sm.albedo_color = Color(color.r, color.g, color.b, 0.65)
		sm.emission = color
	hitbox.activate(damage, is_crit)
	# Animate: grow from center outward
	mesh_instance.scale = Vector3(0.2, 1.0, 0.2)
	var tween := create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3(1, 1, 1), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_interval(hitbox_active_duration).finished.connect(hitbox.deactivate)
	if mat is StandardMaterial3D:
		var sm2: StandardMaterial3D = mat
		tween.tween_property(sm2, "albedo_color:a", 0.0, visual_duration - 0.15)
		tween.parallel().tween_property(sm2, "emission_energy_multiplier", 0.0, visual_duration - 0.15)
	tween.tween_callback(queue_free)
