extends Area3D
## Gold pickup: auto-vacuums toward the player within attract_range,
## consumed when the player's PickupArea touches it.

@export var amount: int = 5
@export var attract_range: float = 6.0
@export var attract_speed: float = 18.0
@export var spawn_pop_strength: float = 3.5  # initial upward/outward jitter

var _player: Node3D
var _picked_up: bool = false
var _initial_y: float = 0.0
var _bob_t: float = 0.0
var _pop_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_initial_y = global_position.y
	# Random pop on spawn so a pile of coins fans out
	_pop_velocity = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(0.6, 1.4),
		randf_range(-1.0, 1.0)
	).normalized() * spawn_pop_strength
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _physics_process(delta: float) -> void:
	if _picked_up:
		return
	# Initial pop phase decays quickly
	if _pop_velocity.length_squared() > 0.001:
		global_position += _pop_velocity * delta
		_pop_velocity = _pop_velocity.move_toward(Vector3.ZERO, 8.0 * delta)
		_pop_velocity.y -= 6.0 * delta  # mini gravity
		if global_position.y < _initial_y + 0.4:
			global_position.y = _initial_y + 0.4
			_pop_velocity.y = 0.0
		return

	# Idle bob + spin
	_bob_t += delta
	global_position.y = _initial_y + 0.4 + sin(_bob_t * 3.5) * 0.1
	rotate_y(delta * 2.5)

	# Attract toward player
	if _player == null:
		return
	var to_player := _player.global_position - global_position
	to_player.y = 0
	var dist := to_player.length()
	if dist < attract_range:
		var pull := to_player.normalized() * attract_speed * (1.0 - dist / attract_range)
		global_position.x += pull.x * delta
		global_position.z += pull.z * delta


func _on_body_entered(body: Node) -> void:
	if _picked_up:
		return
	if body and body.is_in_group("player"):
		_pickup(body)


func _pickup(player_node: Node) -> void:
	_picked_up = true
	# set_deferred — physics is mid-iteration, can't mutate area state inline
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if player_node.has_method("get_inventory"):
		var inv = player_node.get_inventory()
		if inv:
			inv.add_gold(amount)
	queue_free()
