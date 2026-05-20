extends Area3D
## Item pickup: visible 3D object that adds an Item to the player's inventory
## when the player's PickupArea touches it. No auto-vacuum (player chooses to walk over).

@export var item: Item
@export var spawn_pop_strength: float = 2.5

@onready var mesh_instance: MeshInstance3D = $Mesh
@onready var label: Label3D = $NameLabel

var _picked_up: bool = false
var _initial_y: float = 0.0
var _bob_t: float = 0.0
var _pop_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_initial_y = global_position.y
	_pop_velocity = Vector3(
		randf_range(-0.7, 0.7),
		randf_range(0.4, 1.0),
		randf_range(-0.7, 0.7)
	).normalized() * spawn_pop_strength
	_apply_item_visuals()


func setup(item_resource: Item) -> void:
	item = item_resource
	if is_node_ready():
		_apply_item_visuals()


func _apply_item_visuals() -> void:
	if item == null or mesh_instance == null:
		return
	var color := item.get_rarity_color()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.7
	mat.metallic = 0.4
	mat.roughness = 0.4
	mesh_instance.set_surface_override_material(0, mat)
	if label:
		label.text = item.display_name
		label.modulate = color


func _physics_process(delta: float) -> void:
	if _picked_up:
		return
	if _pop_velocity.length_squared() > 0.001:
		global_position += _pop_velocity * delta
		_pop_velocity = _pop_velocity.move_toward(Vector3.ZERO, 6.0 * delta)
		_pop_velocity.y -= 5.0 * delta
		if global_position.y < _initial_y + 0.5:
			global_position.y = _initial_y + 0.5
			_pop_velocity.y = 0.0
		return
	_bob_t += delta
	global_position.y = _initial_y + 0.7 + sin(_bob_t * 2.0) * 0.1
	if mesh_instance:
		mesh_instance.rotate_y(delta * 1.2)


func _on_body_entered(body: Node) -> void:
	if _picked_up or item == null:
		return
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("get_inventory"):
		var inv = body.get_inventory()
		if inv and inv.add_item(item):
			_picked_up = true
			monitoring = false
			monitorable = false
			EventBus.show_floating_text.emit(
				"+ " + item.display_name,
				global_position + Vector3(0, 0.6, 0),
				item.get_rarity_color()
			)
			queue_free()
