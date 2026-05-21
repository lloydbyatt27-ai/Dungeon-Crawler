class_name Mercenary
extends CharacterBody3D
## Player-side AI follower. Follows the player at a fixed distance, breaks
## off to attack enemies in range, then returns. Stats configured by
## `merc_type` at spawn time, sourced from MercenarySystem.MERC_TYPES.

@export var merc_type: String = "warrior"
@export var move_speed: float = 6.0
@export var follow_distance: float = 3.2
@export var leash_distance: float = 14.0
@export var attack_range: float = 2.4
@export var attack_cooldown: float = 1.2
@export var attack_damage: float = 14.0
@export var aggro_range: float = 9.0
@export var gravity: float = 25.0

@onready var body_mesh: MeshInstance3D = $Body
@onready var hitbox: HitBox = $HitBox
@onready var hurtbox: HurtBox = $HurtBox
@onready var health: Health = $Health

var _player: Node3D
var _attack_cd: float = 0.0
var _attack_phase_t: float = 0.0
var _target: Node3D


func _ready() -> void:
	add_to_group("mercenary")
	_apply_type_config()
	# Re-team hurtbox/hitbox so the merc is on the player's side
	if hurtbox:
		hurtbox.team = 1
		hurtbox.collision_layer = 2  # Player layer — so enemies can damage it
	if hitbox:
		hitbox.team = 1
		hitbox.collision_layer = 8  # PlayerHitbox
		hitbox.collision_mask = 4   # Enemy
		hitbox.damage = attack_damage
		hitbox.deactivate()
	health.died.connect(_on_died)


func _apply_type_config() -> void:
	var data: Dictionary = MercenarySystem.MERC_TYPES.get(merc_type, {})
	if data.is_empty():
		return
	if health:
		health.max_health = float(data.get("hp", 200.0))
		health.current_health = health.max_health
	attack_damage = float(data.get("damage", 14.0))
	attack_cooldown = float(data.get("attack_cd", 1.2))
	# Tint the body to the class color
	var color: Color = data.get("body_color", Color(0.7, 0.7, 0.8))
	if body_mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.metallic_specular = 0.3
		mat.roughness = 0.55
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.18
		body_mesh.set_surface_override_material(0, mat)


func _physics_process(delta: float) -> void:
	_attack_cd = max(0.0, _attack_cd - delta)
	if _attack_phase_t > 0.0:
		_attack_phase_t = max(0.0, _attack_phase_t - delta)
		if _attack_phase_t <= 0.0:
			hitbox.deactivate()

	if not is_on_floor():
		velocity.y -= gravity * delta

	# Late-bind to the player
	if _player == null:
		var players := get_tree().get_nodes_in_group("player")
		if players.is_empty():
			move_and_slide()
			return
		_player = players[0]

	# Pick / refresh target enemy
	_target = _find_nearest_enemy()

	if _target and _attack_cd <= 0.0 and _distance_to(_target.global_position) <= attack_range:
		_swing()
	elif _target and _distance_to(_target.global_position) <= aggro_range:
		_move_toward(_target.global_position, delta)
	else:
		# Follow the player
		var to_player: Vector3 = _player.global_position - global_position
		to_player.y = 0.0
		var dist: float = to_player.length()
		if dist > follow_distance:
			_move_toward(_player.global_position, delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)

	# Teleport home if we got way off
	if _player and global_position.distance_to(_player.global_position) > leash_distance * 2.0:
		global_position = _player.global_position + Vector3(1.5, 0.0, 1.5)

	move_and_slide()


func _swing() -> void:
	_attack_cd = attack_cooldown
	_attack_phase_t = 0.2
	# Face the target so the hitbox extends correctly
	var dir: Vector3 = _target.global_position - global_position
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		var yaw: float = atan2(-dir.x, -dir.z)
		rotation.y = yaw
	hitbox.activate(attack_damage, false)


func _move_toward(world_pos: Vector3, delta: float) -> void:
	var dir: Vector3 = world_pos - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		return
	dir = dir.normalized()
	velocity.x = move_toward(velocity.x, dir.x * move_speed, 30.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * move_speed, 30.0 * delta)
	# Face movement direction
	var yaw: float = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, 10.0 * delta)


func _distance_to(world_pos: Vector3) -> float:
	var d: Vector3 = world_pos - global_position
	d.y = 0
	return d.length()


func _find_nearest_enemy() -> Node3D:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var best: Node3D = null
	var best_dist: float = INF
	for e in enemies:
		if e == null or not (e is Node3D):
			continue
		if "state" in e and e.state == e.State.DEAD:
			continue
		var d: float = _distance_to((e as Node3D).global_position)
		if d < best_dist:
			best_dist = d
			best = e
		if best_dist > aggro_range:
			continue
	if best_dist > aggro_range:
		return null
	return best


func _on_died() -> void:
	EventBus.show_floating_text.emit(
		MercenarySystem.MERC_TYPES.get(merc_type, {}).get("display_name", "Mercenary") + " has fallen",
		global_position + Vector3(0, 2.0, 0),
		Color(1.0, 0.4, 0.4)
	)
	queue_free()
