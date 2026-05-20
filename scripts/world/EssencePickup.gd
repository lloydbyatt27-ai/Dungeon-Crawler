extends Area3D
## Purple essence orb dropped by enemies. Auto-vacuums to the player and
## adds to PlayerController.current_essence (capped at 100).

@export var amount: float = 5.0
@export var attract_range: float = 7.0
@export var attract_speed: float = 22.0
@export var spawn_pop_strength: float = 3.0

var _player: Node3D
var _picked_up: bool = false
var _initial_y: float = 0.0
var _bob_t: float = 0.0
var _pop_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_initial_y = global_position.y
	_pop_velocity = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(0.5, 1.2),
		randf_range(-1.0, 1.0)
	).normalized() * spawn_pop_strength
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _physics_process(delta: float) -> void:
	if _picked_up:
		return
	if _pop_velocity.length_squared() > 0.001:
		global_position += _pop_velocity * delta
		_pop_velocity = _pop_velocity.move_toward(Vector3.ZERO, 7.0 * delta)
		_pop_velocity.y -= 6.0 * delta
		if global_position.y < _initial_y + 0.6:
			global_position.y = _initial_y + 0.6
			_pop_velocity.y = 0.0
		return

	_bob_t += delta
	global_position.y = _initial_y + 0.6 + sin(_bob_t * 3.5) * 0.12
	rotate_y(delta * 3.0)

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
	if _picked_up or body == null or not body.is_in_group("player"):
		return
	_pickup(body)


func _pickup(player_node: Node) -> void:
	_picked_up = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if "current_essence" in player_node:
		player_node.current_essence = min(100.0, player_node.current_essence + amount)
		EventBus.player_essence_changed.emit(player_node.current_essence)
	queue_free()
