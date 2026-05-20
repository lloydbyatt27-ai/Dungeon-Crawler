extends StaticBody3D
## Punching-bag dummy. No AI, just takes damage and respawns after a delay.
## Used in the Phase 1 test arena to validate the combat pipeline.

@export var respawn_after: float = 4.0
@export var flash_duration: float = 0.08

@onready var health: Health = $Health
@onready var body_mesh: MeshInstance3D = $Body
@onready var hurtbox: HurtBox = $HurtBox

var _original_material: Material
var _flash_timer: float = 0.0
var _dead: bool = false
var _respawn_timer: float = 0.0
var _start_position: Vector3


func _ready() -> void:
	_start_position = global_position
	_original_material = body_mesh.get_surface_override_material(0)
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)


func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			body_mesh.set_surface_override_material(0, _original_material)

	if _dead:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_respawn()


func _on_damaged(info: DamageInfo) -> void:
	# Flash white briefly
	var flash := StandardMaterial3D.new()
	flash.albedo_color = Color(2.0, 2.0, 2.0)
	flash.emission_enabled = true
	flash.emission = Color(1, 1, 1)
	flash.emission_energy_multiplier = 1.2
	body_mesh.set_surface_override_material(0, flash)
	_flash_timer = flash_duration

	# Pop a damage number
	EventBus.show_damage_number.emit(info.amount, global_position, info.is_crit)


func _on_died() -> void:
	_dead = true
	_respawn_timer = respawn_after
	body_mesh.visible = false
	hurtbox.monitorable = false


func _respawn() -> void:
	_dead = false
	body_mesh.visible = true
	hurtbox.monitorable = true
	health.current_health = health.max_health
	health.is_dead = false
	health.health_changed.emit(health.current_health, health.max_health)
	global_position = _start_position
