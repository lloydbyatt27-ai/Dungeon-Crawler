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

enum Archetype { RUSHER, RANGER, CASTER }

# Stats
@export_group("AI")
@export var archetype: Archetype = Archetype.RUSHER
@export var optimal_range_min: float = 0.0   # rangers/casters kite away if closer than this
@export var optimal_range_max: float = 2.0   # rushers stop chasing past attack_range
@export var projectile_speed: float = 14.0
@export var projectile_color: Color = Color(1.0, 0.3, 0.2)
@export var aoe_radius: float = 3.0
@export var aoe_color: Color = Color(0.8, 0.25, 0.7)
@export var enemy_projectile_scene: PackedScene
@export var enemy_aoe_scene: PackedScene
@export_group("Reward")
@export var xp_value: int = 30
@export var gold_min: int = 3
@export var gold_max: int = 9
@export var item_drop_chance: float = 0.20
@export var essence_value: float = 5.0
@export var essence_drop_chance: float = 0.7
@export var gold_pickup_scene: PackedScene
@export var item_pickup_scene: PackedScene
@export var essence_pickup_scene: PackedScene
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
@export_group("Boss / Enrage")
@export var is_boss: bool = false              # triggers Area Complete + legendary drop
@export var has_enrage_phase: bool = false     # enables phase-2 transition (independent of is_boss)
@export var display_name: String = ""
@export_range(0.0, 1.0) var phase_2_hp_threshold: float = 0.5
@export var phase_2_speed_mult: float = 1.4
@export var phase_2_damage_mult: float = 1.3
@export var phase_2_cooldown_mult: float = 0.7
@export var guaranteed_drop_id: String = ""
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
var _phase: int = 1

# Caster telegraph: anchor to a world position instead of in front of the enemy
var _telegraph_anchored: bool = false
var _telegraph_world_anchor: Vector3 = Vector3.ZERO
var _telegraph_default_scale: Vector3 = Vector3.ONE

@onready var health: Health = $Health
@onready var hurtbox: HurtBox = $HurtBox
@onready var attack_hitbox: HitBox = $AttackHitBox
@onready var body_mesh: MeshInstance3D = $Body
@onready var telegraph_mesh: MeshInstance3D = $TelegraphMesh

var status_effects: StatusEffectComponent
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
	_telegraph_default_scale = telegraph_mesh.scale

	# Runtime-add a StatusEffectComponent (avoids editing every enemy scene)
	status_effects = StatusEffectComponent.new()
	status_effects.name = "StatusEffectComponent"
	add_child(status_effects)
	status_effects.owner_health_path = NodePath("../Health")
	status_effects._health = health
	hurtbox.set_status_component(status_effects)
	status_effects.status_added.connect(_on_status_added)

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _on_status_added(effect_name: String) -> void:
	var color := Color(1, 1, 1)
	match effect_name:
		"slow":    color = Color(0.6, 0.8, 1.0)
		"stun":    color = Color(1.0, 0.95, 0.4)
		"freeze":  color = Color(0.5, 0.9, 1.0)
		"burn":    color = Color(1.0, 0.5, 0.2)
		"bleed":   color = Color(1.0, 0.25, 0.25)
		"poison":  color = Color(0.6, 1.0, 0.3)
	EventBus.show_floating_text.emit(
		effect_name.to_upper(),
		global_position + Vector3(0, 2.4, 0),
		color
	)


func _physics_process(delta: float) -> void:
	_attack_cd = max(0.0, _attack_cd - delta)
	_state_timer = max(0.0, _state_timer - delta)

	# Late-bind to player if we spawned before the player joined the group
	if _player == null:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			_player = players[0]

	# Hit flash decay
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			body_mesh.set_surface_override_material(0, _body_default_material)

	if not is_on_floor():
		velocity.y -= gravity * delta

	# Stunned / frozen — freeze in place, skip state ticks
	if status_effects and status_effects.is_disabled() and state != State.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, friction * 2.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * 2.0 * delta)
		move_and_slide()
		return

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

	var in_zone := false
	var move_dir := Vector3.ZERO

	match archetype:
		Archetype.RUSHER:
			in_zone = dist <= attack_range
			if not in_zone:
				move_dir = _player.global_position - global_position
		Archetype.RANGER, Archetype.CASTER:
			in_zone = dist >= optimal_range_min and dist <= optimal_range_max
			if dist < optimal_range_min:
				move_dir = global_position - _player.global_position   # back away
			elif dist > optimal_range_max:
				move_dir = _player.global_position - global_position   # close in

	if in_zone and _attack_cd <= 0.0:
		_enter(State.TELEGRAPH)
		return

	move_dir.y = 0
	var slow_mult: float = status_effects.move_speed_multiplier() if status_effects else 1.0
	if move_dir.length_squared() > 0.01:
		var d := move_dir.normalized()
		velocity.x = move_toward(velocity.x, d.x * move_speed * slow_mult, acceleration * delta)
		velocity.z = move_toward(velocity.z, d.z * move_speed * slow_mult, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)


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
	# Keep the caster's warning circle pinned to its locked world position
	if _telegraph_anchored:
		telegraph_mesh.global_position = _telegraph_world_anchor
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
			if archetype == Archetype.CASTER:
				_telegraph_anchored = false
				telegraph_mesh.scale = _telegraph_default_scale
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
			# Caster locks the warning circle to the player's position at telegraph start
			if archetype == Archetype.CASTER and _player:
				_telegraph_anchored = true
				_telegraph_world_anchor = _player.global_position
				_telegraph_world_anchor.y = 0.05
				var s: float = aoe_radius * 1.4
				telegraph_mesh.scale = Vector3(s, 1.0, s)
		State.ACTIVE:
			_state_timer = active_duration
			match archetype:
				Archetype.RUSHER:  attack_hitbox.activate(attack_damage)
				Archetype.RANGER:  _fire_projectile_attack()
				Archetype.CASTER:  _drop_aoe_attack()
		State.RECOVER:
			_state_timer = recovery_duration
			_attack_cd = attack_cooldown
		State.STAGGER:
			_state_timer = stagger_duration
			telegraph_mesh.visible = false
			attack_hitbox.deactivate()
			_telegraph_anchored = false
		State.DEAD:
			_state_timer = 0.0


# --- Health hooks ----------------------------------------------------

func _on_damaged(info: DamageInfo) -> void:
	if state == State.DEAD:
		return
	EventBus.show_damage_number.emit(info.amount, global_position, info.is_crit)
	_flash_white()
	# Interrupt attacks unless we're enraged (bosses AND non-boss berserkers gain super armor in phase 2)
	var has_phase: bool = is_boss or has_enrage_phase
	var interruptible: bool = not (has_phase and _phase >= 2)
	if interruptible and state in [State.TELEGRAPH, State.ACTIVE]:
		_enter(State.STAGGER)
	# Phase transition (boss enrage OR berserker enrage)
	if has_phase and _phase == 1 and health.health_percent() <= phase_2_hp_threshold:
		_enter_phase_2()


func _on_died() -> void:
	_enter(State.DEAD)
	attack_hitbox.deactivate()
	# set_deferred — Health.died is emitted from inside physics signal processing
	hurtbox.set_deferred("monitorable", false)
	telegraph_mesh.visible = false
	_drop_loot()
	EventBus.enemy_died.emit(self, global_position)
	if is_boss:
		EventBus.boss_defeated.emit(self)
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
	# Essence
	if essence_pickup_scene and essence_value > 0.0 and randf() < essence_drop_chance:
		var orb := essence_pickup_scene.instantiate()
		get_tree().current_scene.add_child(orb)
		orb.amount = essence_value
		orb.global_position = global_position + Vector3(0, 0.7, 0)
	# Random item
	if item_pickup_scene and randf() < item_drop_chance:
		var item := ItemDatabase.generate_random_item(1)
		if item:
			_spawn_item_pickup(item)
	# Guaranteed boss drop
	if is_boss and guaranteed_drop_id != "":
		var unique := ItemDatabase.create_by_id(guaranteed_drop_id)
		if unique:
			_spawn_item_pickup(unique, Vector3(randf_range(-0.6, 0.6), 0.6, randf_range(-0.6, 0.6)))


func _spawn_item_pickup(item: Item, offset: Vector3 = Vector3(0, 0.6, 0)) -> void:
	if item_pickup_scene == null:
		return
	var pickup := item_pickup_scene.instantiate()
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position + offset
	pickup.setup(item)


func _enter_phase_2() -> void:
	_phase = 2
	move_speed *= phase_2_speed_mult
	attack_damage *= phase_2_damage_mult
	attack_cooldown *= phase_2_cooldown_mult
	telegraph_duration *= 0.75  # faster telegraph too
	# Visual: glow red
	var enrage_mat := StandardMaterial3D.new()
	enrage_mat.albedo_color = Color(1.0, 0.4, 0.2)
	enrage_mat.emission_enabled = true
	enrage_mat.emission = Color(1.0, 0.2, 0.1)
	enrage_mat.emission_energy_multiplier = 0.8
	body_mesh.set_surface_override_material(0, enrage_mat)
	_body_default_material = enrage_mat
	EventBus.show_floating_text.emit(
		"ENRAGED!" if display_name == "" else display_name.to_upper() + " ENRAGED!",
		global_position + Vector3(0, 2.5, 0),
		Color(1.0, 0.3, 0.1)
	)


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


## Spawn an enemy projectile aimed at the player. Re-teams the projectile's
## HitBox so it damages the player (not other enemies).
func _fire_projectile_attack() -> void:
	if enemy_projectile_scene == null or _player == null:
		return
	var proj := enemy_projectile_scene.instantiate() as ProjectileEffect
	get_tree().current_scene.add_child(proj)
	proj.color = projectile_color
	proj.speed = projectile_speed
	proj.radius = 0.32
	# Re-team the hitbox: enemy attack hits player layer
	proj.hitbox.team = 2
	proj.hitbox.collision_layer = 16  # EnemyHitbox
	proj.hitbox.collision_mask = 2    # Player
	var src := global_position
	var dir := (_player.global_position - src)
	dir.y = 0.0
	if dir.length() < 0.01:
		dir = -global_transform.basis.z
	proj.setup(attack_damage, false, dir.normalized(), src)


## Drop an AoE at the previously-locked telegraph position.
func _drop_aoe_attack() -> void:
	if enemy_aoe_scene == null:
		return
	var aoe := enemy_aoe_scene.instantiate() as AoEEffect
	get_tree().current_scene.add_child(aoe)
	# Re-team: enemy attack hits player
	aoe.hitbox.team = 2
	aoe.hitbox.collision_layer = 16
	aoe.hitbox.collision_mask = 2
	# Position at the telegraph anchor; height handled by the effect itself
	aoe.global_position = _telegraph_world_anchor
	aoe.setup(attack_damage, false, aoe_radius, aoe_color)


func _flash_white() -> void:
	var flash := StandardMaterial3D.new()
	flash.albedo_color = Color(2.0, 2.0, 2.0)
	flash.emission_enabled = true
	flash.emission = Color(1, 1, 1)
	flash.emission_energy_multiplier = 1.5
	body_mesh.set_surface_override_material(0, flash)
	_flash_timer = 0.08
