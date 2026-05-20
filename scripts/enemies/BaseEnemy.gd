class_name BaseEnemy
extends CharacterBody3D
## Phase 1 melee enemy: state machine + chase + telegraphed attack.
## State flow:
##   IDLE  ──aggro range──> AGGRO ──in attack range──> TELEGRAPH
##                                                       │
##                                                       v
##   AGGRO <──recovery────── RECOVER <───active── ACTIVE
##
## Hit while attacking → STAGGER → AGGRO (interrupts swing).
## Health.died → DEAD.

# Stats
@export_group("Reward")
@export var xp_value: int = 30
@export var gold_min: int = 3
@export var gold_max: int = 9
@export var item_drop_chance: float = 0.20
@export var gold_pickup_scene: PackedScene
@export var item_pickup_scene: PackedScene
@export_group("Combat")
@export var attack_damage: float = 12.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.6
@export var telegraph_duration: float = 0.55
@export var active_duration: float = 0.18
@export var recovery_duration: float = 0.45
@export var stagger_duration: float = 0.25
@export_group("Movement")
@export var move_speed: float = 4.5
@export var acceleration: float = 28.0
@export var friction: float = 22.0
@export var rotation_speed: float = 10.0
@export_group("Perception")
@export var aggro_range: float = 12.0
@export var leash_range: float = 18.0
@export_group("Physics")
@export var gravity: float = 25.0

enum State { IDLE, AGGRO, TELEGRAPH, ACTIVE, RECOVER, STAGGER, DEAD }
var state: State = State.IDLE
var _state_timer: float = 0.0
var _attack_cd: float = 0.0
var _facing_dir: Vector3 = Vector3.FORWARD

@onready var health: Health = $Health
@onready var hurtbox: HurtBox = $HurtBox
@onready var attack_hitbox: HitBox = $AttackHitBox
@onready var body_mesh: MeshInstance3D = $Body
@onready var telegraph_mesh: MeshInstance3D = $TelegraphMesh

var _player: Node3D
var _body_default_material: Material
var _flash_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemy")
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	telegraph_mesh.visible = false
	attack_hitbox.deactivate()
	_body_default_material = body_mesh.get_surface_override_material(0)

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _physics_process(delta: float) -> void:
	_attack_cd = max(0.0, _attack_cd - delta)
	_state_timer = max(0.0, _state_timer - delta)

	# Hit flash decay
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			body_mesh.set_surface_override_material(0, _body_default_material)

	if not is_on_floor():
		velocity.y -= gravity * delta

	match state:
		State.IDLE:        _tick_idle(delta)
		State.AGGRO:       _tick_aggro(delta)
		State.TELEGRAPH:   _tick_telegraph(delta)
		State.ACTIVE:      _tick_active(delta)
		State.RECOVER:     _tick_recover(delta)
		State.STAGGER:     _tick_stagger(delta)
		State.DEAD:
			velocity.x = 0
			velocity.z = 0

	move_and_slide()

	# Always face the player when alive and in combat
	if state in [State.AGGRO, State.TELEGRAPH, State.ACTIVE, State.RECOVER] and _player:
		var to_player := _player.global_position - global_position
		to_player.y = 0
		if to_player.length_squared() > 0.01:
			_facing_dir = to_player.normalized()
			_rotate_toward(_facing_dir, delta)


# --- States ----------------------------------------------------------

func _tick_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	velocity.z = move_toward(velocity.z, 0, friction * delta)
	if _player and _distance_to_player() <= aggro_range:
		_enter(State.AGGRO)


func _tick_aggro(delta: float) -> void:
	if _player == null:
		_enter(State.IDLE)
		return
	var dist := _distance_to_player()
	if dist > leash_range:
		_enter(State.IDLE)
		return
	if dist <= attack_range and _attack_cd <= 0.0:
		_enter(State.TELEGRAPH)
		return

	var to_player := _player.global_position - global_position
	to_player.y = 0
	var dir := to_player.normalized()
	velocity.x = move_toward(velocity.x, dir.x * move_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, dir.z * move_speed, acceleration * delta)


func _tick_telegraph(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	# Pulse the telegraph alpha as we wind up
	var t: float = 1.0 - (_state_timer / telegraph_duration)
	var mat := telegraph_mesh.get_surface_override_material(0)
	if mat is StandardMaterial3D:
		var sm: StandardMaterial3D = mat
		sm.albedo_color.a = 0.35 + 0.45 * t
		sm.emission_energy_multiplier = 0.5 + 1.5 * t
	if _state_timer <= 0.0:
		_enter(State.ACTIVE)


func _tick_active(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	if _state_timer <= 0.0:
		_enter(State.RECOVER)


func _tick_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	velocity.z = move_toward(velocity.z, 0, friction * delta)
	if _state_timer <= 0.0:
		_enter(State.AGGRO)


func _tick_stagger(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, friction * 2.0 * delta)
	velocity.z = move_toward(velocity.z, 0, friction * 2.0 * delta)
	if _state_timer <= 0.0:
		_enter(State.AGGRO)


# --- Transitions -----------------------------------------------------

func _enter(new_state: State) -> void:
	# Exit
	match state:
		State.TELEGRAPH:
			telegraph_mesh.visible = false
		State.ACTIVE:
			attack_hitbox.deactivate()

	state = new_state

	# Enter
	match new_state:
		State.IDLE:
			_state_timer = 0.0
		State.AGGRO:
			_state_timer = 0.0
		State.TELEGRAPH:
			_state_timer = telegraph_duration
			telegraph_mesh.visible = true
		State.ACTIVE:
			_state_timer = active_duration
			attack_hitbox.activate(attack_damage)
		State.RECOVER:
			_state_timer = recovery_duration
			_attack_cd = attack_cooldown
		State.STAGGER:
			_state_timer = stagger_duration
			telegraph_mesh.visible = false
			attack_hitbox.deactivate()
		State.DEAD:
			_state_timer = 0.0


# --- Health hooks ----------------------------------------------------

func _on_damaged(info: DamageInfo) -> void:
	if state == State.DEAD:
		return
	EventBus.show_damage_number.emit(info.amount, global_position, info.is_crit)
	_flash_white()
	# Interrupt attacks if hit during windup or active
	if state in [State.TELEGRAPH, State.ACTIVE]:
		_enter(State.STAGGER)


func _on_died() -> void:
	_enter(State.DEAD)
	attack_hitbox.deactivate()
	hurtbox.monitorable = false
	telegraph_mesh.visible = false
	_drop_loot()
	EventBus.enemy_died.emit(self, global_position)
	# Fall over and fade out
	_die_animation()


func _drop_loot() -> void:
	# Gold
	if gold_pickup_scene:
		var amount := randi_range(gold_min, gold_max)
		if amount > 0:
			var pile := gold_pickup_scene.instantiate()
			get_tree().current_scene.add_child(pile)
			pile.amount = amount
			pile.global_position = global_position + Vector3(0, 0.5, 0)
	# Item
	if item_pickup_scene and randf() < item_drop_chance:
		var item := ItemDatabase.generate_random_item(1)
		if item:
			var pickup := item_pickup_scene.instantiate()
			get_tree().current_scene.add_child(pickup)
			pickup.global_position = global_position + Vector3(0, 0.6, 0)
			pickup.setup(item)


func _die_animation() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(body_mesh, "rotation:x", deg_to_rad(-90.0), 0.4)
	tween.tween_property(self, "position:y", position.y - 0.4, 0.4)
	tween.chain().tween_interval(1.0)
	tween.chain().tween_property(body_mesh, "transparency", 1.0, 0.4)
	tween.chain().tween_callback(queue_free)


# --- Utils -----------------------------------------------------------

func _distance_to_player() -> float:
	if _player == null:
		return INF
	var to_player := _player.global_position - global_position
	to_player.y = 0
	return to_player.length()


func _rotate_toward(direction: Vector3, delta: float) -> void:
	# Godot's default forward is local -Z, so yaw to face `direction` is atan2(-x, -z).
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)


func _flash_white() -> void:
	var flash := StandardMaterial3D.new()
	flash.albedo_color = Color(2.0, 2.0, 2.0)
	flash.emission_enabled = true
	flash.emission = Color(1, 1, 1)
	flash.emission_energy_multiplier = 1.5
	body_mesh.set_surface_override_material(0, flash)
	_flash_timer = 0.08
