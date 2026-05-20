class_name ProjectileEffect
extends Node3D
## Forward-traveling projectile (Throw Knife, Fireball, Snipe).
## Spawns at caster, flies in caster's facing direction, despawns on first
## hit (HitBox.auto_deactivate) or after max_distance.

@export var speed: float = 22.0
@export var max_distance: float = 30.0
@export var damage: float = 16.0
@export var color: Color = Color(1, 1, 1)
@export var radius: float = 0.4

@onready var mesh_instance: MeshInstance3D = $Mesh
@onready var hitbox: HitBox = $HitBox
@onready var hitbox_shape: CollisionShape3D = $HitBox/Shape

var _direction: Vector3 = Vector3.FORWARD
var _traveled: float = 0.0
var _alive: bool = true


func setup(dmg: float, is_crit: bool, dir: Vector3, source_pos: Vector3) -> void:
	damage = dmg
	_direction = dir.normalized()
	global_position = source_pos + Vector3(0, 1.0, 0)
	# Tint and scale
	var mat := mesh_instance.get_surface_override_material(0)
	if mat is StandardMaterial3D:
		var sm: StandardMaterial3D = mat
		sm.albedo_color = color
		sm.emission = color
		sm.emission_energy_multiplier = 1.8
	if hitbox_shape.shape is SphereShape3D:
		(hitbox_shape.shape as SphereShape3D).radius = radius
	mesh_instance.scale = Vector3.ONE * (radius / 0.4)
	# Activate damage
	hitbox.activate(damage, is_crit)
	hitbox.auto_deactivate = true
	hitbox.hit_landed.connect(_on_hit_landed)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	var step: Vector3 = _direction * speed * delta
	global_position += step
	_traveled += step.length()
	# Spin for visual flair
	mesh_instance.rotate_y(delta * 10.0)
	if _traveled >= max_distance:
		_die()


func _on_hit_landed(_target: HurtBox, _info: DamageInfo) -> void:
	_die()


func _die() -> void:
	if not _alive:
		return
	_alive = false
	# Flash burst then despawn
	var tween := create_tween()
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale * 2.5, 0.12)
	var mat := mesh_instance.get_surface_override_material(0)
	if mat is StandardMaterial3D:
		tween.parallel().tween_property(mat, "emission_energy_multiplier", 0.0, 0.15)
		tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
