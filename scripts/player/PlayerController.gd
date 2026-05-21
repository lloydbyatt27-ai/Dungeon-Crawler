class_name PlayerController
extends CharacterBody3D
## Player movement, input, and combat.
## Phase 1 Week 4: stats-driven HP/mana/damage, crit rolls, XP & level-up,
## three Guardian skills (Q/E/R) wired through SkillSystem.

@export var stats: CharacterStats
@export_group("Movement")
@export var move_speed: float = 6.0
@export var acceleration: float = 40.0
@export var friction: float = 35.0
@export var rotation_speed: float = 12.0
@export_group("Dodge")
@export var dodge_speed: float = 14.0
@export var dodge_duration: float = 0.35
@export var dodge_cooldown: float = 0.6
@export var iframe_window: Vector2 = Vector2(0.05, 0.30)  # iframes start..end within dodge
@export_group("Physics")
@export var gravity: float = 25.0

# Light combo phases: (startup, active, recovery, damage)
const LIGHT_PHASES: Array = [
	{"startup": 0.08, "active": 0.10, "recovery": 0.22, "damage": 10.0},  # L1
	{"startup": 0.10, "active": 0.10, "recovery": 0.24, "damage": 12.0},  # L2
	{"startup": 0.14, "active": 0.14, "recovery": 0.36, "damage": 18.0},  # L3 finisher
]
const HEAVY_PHASE: Dictionary = {"startup": 0.28, "active": 0.16, "recovery": 0.46, "damage": 30.0}
const COMBO_WINDOW: float = 1.0  # after attack, time to chain next light hit

# State
enum State { IDLE, MOVING, ATTACKING, DODGING, STAGGERED, DEAD }
var state: State = State.IDLE

# Dodge
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO
var _hurtbox_default_layer: int = 0

# Attack
enum AttackPhase { NONE, STARTUP, ACTIVE, RECOVERY }
var attack_phase: AttackPhase = AttackPhase.NONE
var attack_phase_timer: float = 0.0
var current_attack: Dictionary = {}
var combo_counter: int = 0       # 0..3 (which light hit we are in)
var combo_window_timer: float = 0.0
var buffered_attack: String = ""  # "light" or "heavy" buffered during recovery

# Runtime resources (stats hold the maxes; these track current values)
var current_mana: float = 0.0
var current_essence: float = 0.0  # 0-100, shapeshift fuel

# Source of the last damage taken — captured for the death recap so we
# can attribute the kill to a specific enemy / source.
var last_damage_source: Node

# Nodes
@onready var health: Health = $Health
@onready var hurtbox: HurtBox = $HurtBox
@onready var melee_hitbox: HitBox = $MeleeHitBox
@onready var body_mesh: MeshInstance3D = $Body
@onready var skill_system: SkillSystem = $SkillSystem
@onready var inventory: Inventory = $Inventory
@onready var shape_shift: ShapeShiftSystem = $ShapeShiftSystem

# Visuals
var _body_default_material: Material
var _flash_timer: float = 0.0

# Facing
var facing_direction: Vector3 = Vector3.FORWARD


func _ready() -> void:
	add_to_group("player")
	if stats == null:
		stats = CharacterStats.new()
	_hurtbox_default_layer = hurtbox.collision_layer
	_body_default_material = body_mesh.get_surface_override_material(0)
	# Apply stats → resources
	health.set_max_health(stats.max_hp(), true)
	current_mana = stats.max_mana()
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	# Listen for enemy deaths so we gain XP
	EventBus.enemy_died.connect(_on_enemy_died)
	# If the SaveSystem has a pending payload, overwrite default stats/inventory
	if SaveSystem.pending_load_data and not SaveSystem.pending_load_data.is_empty():
		SaveSystem.apply_to_player(self)
	# Otherwise, apply a freshly-chosen class preset from ClassSelect
	elif SaveSystem.pending_class != "":
		stats.apply_class_preset(SaveSystem.pending_class)
		stats.hardcore = SaveSystem.pending_hardcore
		SaveSystem.pending_class = ""
		SaveSystem.pending_hardcore = false
		# Re-apply derived resources with the new class's max HP / mana
		health.set_max_health(stats.max_hp(), true)
		current_mana = stats.max_mana()
	# Apply class-specific configuration (body tint + active skills)
	_apply_class_visuals_and_skills()
	# Spawn the player's mercenary follower, if any
	_spawn_mercenary_if_hired()
	# Mark the start of a fresh run for the area-complete summary
	GameState.start_run()


func _spawn_mercenary_if_hired() -> void:
	if not MercenarySystem.has_active_merc():
		return
	# Don't double-spawn if one already exists in the scene
	if not get_tree().get_nodes_in_group("mercenary").is_empty():
		return
	var scene: PackedScene = load("res://scenes/world/Mercenary.tscn")
	if scene == null:
		return
	var merc := scene.instantiate()
	merc.merc_type = MercenarySystem.current_type
	get_tree().current_scene.add_child(merc)
	merc.global_position = global_position + Vector3(1.6, 0.0, 1.6)


func _apply_class_visuals_and_skills() -> void:
	if stats == null:
		return
	var class_data: Dictionary = ClassDatabase.get_class_data(stats.class_type)
	# Body tint
	var color: Color = class_data.get("body_color", Color(0.85, 0.55, 0.30))
	var class_mat := StandardMaterial3D.new()
	class_mat.albedo_color = color
	class_mat.metallic_specular = 0.3
	class_mat.roughness = 0.55
	body_mesh.set_surface_override_material(0, class_mat)
	_body_default_material = class_mat
	# Active skills — prefer the character's saved loadout, fall back to
	# the class's starter set. Mirror the result back onto stats so the
	# Skill Trainer always has a known starting point to edit from.
	var skills: Array = stats.active_skill_ids
	if skills.is_empty():
		skills = class_data.get("starter_skills", ["earthquake", "warcry", "frostbite"])
		stats.active_skill_ids.clear()
		for s in skills:
			stats.active_skill_ids.append(String(s))
	if skill_system:
		skill_system.set_active_skills(skills)


func _physics_process(delta: float) -> void:
	dodge_cooldown_timer = max(0.0, dodge_cooldown_timer - delta)
	combo_window_timer = max(0.0, combo_window_timer - delta)
	if combo_window_timer <= 0.0:
		combo_counter = 0

	# Hit flash decay
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			body_mesh.set_surface_override_material(0, _body_default_material)

	# Mana regen
	if stats and current_mana < stats.max_mana():
		current_mana = min(stats.max_mana(), current_mana + stats.mana_regen_per_sec() * delta)

	# HP regen out of combat (simple: always regen at low rate)
	if stats and not health.is_dead and health.current_health < health.max_health:
		health.heal(stats.hp_regen_per_sec() * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta

	# Potion hotkeys (1-4) work regardless of state, so you can drink
	# while attacking, dodging, etc.
	_handle_potion_hotkeys()

	match state:
		State.IDLE, State.MOVING:
			_handle_movement(delta)
			_handle_combat_input()
		State.DODGING:
			_process_dodge(delta)
		State.ATTACKING:
			_process_attack(delta)
			_buffer_combat_input()
			# Allow some drift during attacks
			velocity.x = move_toward(velocity.x, 0, friction * 1.5 * delta)
			velocity.z = move_toward(velocity.z, 0, friction * 1.5 * delta)
		State.STAGGERED:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			velocity.z = move_toward(velocity.z, 0, friction * delta)
		State.DEAD:
			velocity = Vector3.ZERO

	move_and_slide()


# --- Movement ----------------------------------------------------------

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := _camera_relative_input(input_dir)

	if direction.length_squared() > 0.01:
		velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
		facing_direction = direction
		_rotate_toward(direction, delta)
		state = State.MOVING
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		if state == State.MOVING:
			state = State.IDLE


func _camera_relative_input(input_dir: Vector2) -> Vector3:
	# W (move_up) makes input_dir.y = -1, but we want it to move the player
	# AWAY from the camera (up on screen), so we negate Y.
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return Vector3(input_dir.x, 0.0, -input_dir.y)

	var cam_basis := cam.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	return (right * input_dir.x - forward * input_dir.y).normalized()


func _rotate_toward(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001:
		return
	# Godot's default forward is local -Z, so the yaw that makes -Z point
	# along `direction` is atan2(-x, -z), not atan2(x, z).
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)


# --- Input dispatch ---------------------------------------------------

func _handle_combat_input() -> void:
	if Input.is_action_just_pressed("dodge") and dodge_cooldown_timer <= 0.0:
		_start_dodge()
		return
	if Input.is_action_just_pressed("attack_light"):
		_start_light_attack()
		return
	if Input.is_action_just_pressed("attack_heavy"):
		_start_heavy_attack()
		return


func _handle_potion_hotkeys() -> void:
	if inventory == null:
		return
	for i in range(4):
		if Input.is_action_just_pressed("potion_%d" % (i + 1)):
			inventory.use_belt_potion(i)
			return


func _buffer_combat_input() -> void:
	# During an attack, queue the next action for the recovery transition
	if attack_phase != AttackPhase.RECOVERY:
		return
	if Input.is_action_just_pressed("attack_light"):
		buffered_attack = "light"
	elif Input.is_action_just_pressed("attack_heavy"):
		buffered_attack = "heavy"
	elif Input.is_action_just_pressed("dodge") and dodge_cooldown_timer <= 0.0:
		# Dodge cancels recovery immediately
		_start_dodge()


# --- Dodge -------------------------------------------------------------

func _start_dodge() -> void:
	# Cancel any attack
	_cancel_attack()

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := _camera_relative_input(input_dir)
	if dir.length_squared() < 0.01:
		dir = -global_transform.basis.z  # dodge forward if no input
	dodge_direction = dir.normalized()
	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown
	state = State.DODGING
	# Face the dodge direction
	_rotate_toward(dodge_direction, 1.0)
	# Enable iframes (briefly disable hurtbox from being detected)
	# Actual toggle is timed in _process_dodge


func _process_dodge(delta: float) -> void:
	var elapsed := dodge_duration - dodge_timer
	# iframes: turn HurtBox off while inside window, on outside
	var in_iframes := elapsed >= iframe_window.x and elapsed <= iframe_window.y
	hurtbox.monitorable = not in_iframes

	dodge_timer -= delta
	velocity.x = dodge_direction.x * dodge_speed
	velocity.z = dodge_direction.z * dodge_speed
	if dodge_timer <= 0.0:
		hurtbox.monitorable = true
		state = State.IDLE


# --- Attacks -----------------------------------------------------------

func _start_light_attack() -> void:
	combo_counter = (combo_counter % 3) + 1
	combo_window_timer = COMBO_WINDOW
	current_attack = LIGHT_PHASES[combo_counter - 1]
	_enter_attack_phase(AttackPhase.STARTUP)
	state = State.ATTACKING
	EventBus.sfx_attack_swing.emit()


func _start_heavy_attack() -> void:
	combo_counter = 0  # heavy resets light combo
	current_attack = HEAVY_PHASE
	_enter_attack_phase(AttackPhase.STARTUP)
	state = State.ATTACKING
	EventBus.sfx_attack_swing.emit()


func _enter_attack_phase(phase: AttackPhase) -> void:
	attack_phase = phase
	match phase:
		AttackPhase.STARTUP:
			attack_phase_timer = current_attack.startup
			melee_hitbox.deactivate()
		AttackPhase.ACTIVE:
			attack_phase_timer = current_attack.active
			var dmg := _compute_melee_damage(current_attack.damage)
			var is_crit := _roll_crit()
			if is_crit:
				dmg *= stats.crit_damage_mult() if stats else 1.5
			melee_hitbox.activate(dmg, is_crit)
		AttackPhase.RECOVERY:
			attack_phase_timer = current_attack.recovery
			melee_hitbox.deactivate()
		AttackPhase.NONE:
			melee_hitbox.deactivate()


func _compute_melee_damage(weapon_base: float) -> float:
	# Base = unarmed swing damage from LIGHT_PHASES + equipped weapon damage.
	var dmg := weapon_base
	if stats:
		dmg += stats.bonus_weapon_damage
		dmg *= stats.melee_damage_mult()
	if skill_system:
		dmg *= (1.0 + skill_system.damage_buff_amount)
	if shape_shift:
		dmg *= shape_shift.damage_mult()
	return dmg


func get_inventory() -> Inventory:
	return inventory


func _roll_crit() -> bool:
	if stats == null:
		return false
	return randf() < stats.crit_chance()


func _process_attack(delta: float) -> void:
	if attack_phase == AttackPhase.NONE:
		state = State.IDLE
		return

	attack_phase_timer -= delta
	if attack_phase_timer > 0.0:
		return

	match attack_phase:
		AttackPhase.STARTUP:
			_enter_attack_phase(AttackPhase.ACTIVE)
		AttackPhase.ACTIVE:
			_enter_attack_phase(AttackPhase.RECOVERY)
		AttackPhase.RECOVERY:
			# Consume buffered input or return to idle
			if buffered_attack == "light":
				buffered_attack = ""
				_start_light_attack()
			elif buffered_attack == "heavy":
				buffered_attack = ""
				_start_heavy_attack()
			else:
				attack_phase = AttackPhase.NONE
				state = State.IDLE


func _cancel_attack() -> void:
	attack_phase = AttackPhase.NONE
	attack_phase_timer = 0.0
	melee_hitbox.deactivate()
	buffered_attack = ""


# --- Damage / death ----------------------------------------------------

func _on_damaged(info: DamageInfo) -> void:
	if state == State.DEAD:
		return
	if state == State.ATTACKING:
		_cancel_attack()
	if info and info.source:
		last_damage_source = info.source
	_flash_red()
	EventBus.player_took_damage.emit(info.amount, info.source)


func _on_died() -> void:
	state = State.DEAD
	_cancel_attack()
	melee_hitbox.deactivate()
	hurtbox.set_deferred("monitorable", false)
	# Record this run in history before the scene transitions to menu
	var killer_name: String = ""
	if last_damage_source:
		if "display_name" in last_damage_source and String(last_damage_source.display_name) != "":
			killer_name = String(last_damage_source.display_name)
		else:
			killer_name = last_damage_source.name
	RunHistory.record_death(self, killer_name)
	# Topple the body
	var tween := create_tween()
	tween.tween_property(body_mesh, "rotation:x", deg_to_rad(-90.0), 0.5)
	tween.parallel().tween_property(self, "position:y", position.y - 0.3, 0.5)


func _flash_red() -> void:
	var flash := StandardMaterial3D.new()
	flash.albedo_color = Color(1.6, 0.25, 0.25)
	flash.emission_enabled = true
	flash.emission = Color(1.0, 0.1, 0.1)
	flash.emission_energy_multiplier = 1.4
	body_mesh.set_surface_override_material(0, flash)
	_flash_timer = 0.12


# --- XP / leveling ---------------------------------------------------

func _on_enemy_died(enemy: Node, _pos: Vector3) -> void:
	if stats == null:
		return
	var xp_value: int = 25
	if "xp_value" in enemy:
		xp_value = enemy.xp_value
	gain_xp(xp_value)


func gain_xp(amount: int) -> void:
	if stats == null:
		return
	var result := stats.gain_xp(amount)
	EventBus.player_xp_gained.emit(amount)
	if result.levels_gained > 0:
		# Refill HP/Mana on level-up
		health.set_max_health(stats.max_hp(), false)
		health.heal(stats.max_hp())  # full heal
		current_mana = stats.max_mana()
		EventBus.player_leveled_up.emit(stats.level)
		EventBus.show_floating_text.emit(
			"LEVEL %d!" % stats.level,
			global_position + Vector3(0, 2.0, 0),
			Color(1, 0.85, 0.3)
		)
	if result.paragon_gained > 0:
		# Paragon up: emit signal-equivalent floating text + stats refresh
		EventBus.show_floating_text.emit(
			"PARAGON %d!" % stats.paragon_level,
			global_position + Vector3(0, 2.0, 0),
			Color(1.0, 0.55, 1.0)
		)
		EventBus.player_stats_changed.emit()
