extends Area3D
## Item pickup: visible 3D object that adds an Item to the player's inventory
## when the player's PickupArea touches it. No auto-vacuum (player chooses to walk over).

@export var item: Item
@export var spawn_pop_strength: float = 2.5
@export var magnetism_radius: float = 3.0
@export var magnetism_speed: float = 9.0

@onready var mesh_instance: MeshInstance3D = $Mesh
@onready var label: Label3D = $NameLabel

var _picked_up: bool = false
var _initial_y: float = 0.0
var _bob_t: float = 0.0
var _pop_velocity: Vector3 = Vector3.ZERO
var _beam: MeshInstance3D
var _player: Node3D


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
	# Loot beam — RARE+ items get a tall vertical column visible at distance
	if int(item.rarity) >= int(Item.Rarity.RARE):
		_spawn_loot_beam(color)
	# Dim items below the loot filter so they read as "ignored" in-world.
	if _is_filtered_out():
		mesh_instance.transparency = 0.45
		if label:
			label.modulate.a = 0.45
		if _beam:
			_beam.transparency = 0.7


func _spawn_loot_beam(color: Color) -> void:
	if _beam:
		_beam.queue_free()
	_beam = MeshInstance3D.new()
	add_child(_beam)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.32
	cyl.height = 5.0
	_beam.mesh = cyl
	_beam.position = Vector3(0, 2.6, 0)
	var bmat := StandardMaterial3D.new()
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.albedo_color = Color(color.r, color.g, color.b, 0.35)
	bmat.emission_enabled = true
	bmat.emission = color
	bmat.emission_energy_multiplier = 2.4
	# Slightly brighter for higher rarities
	if int(item.rarity) >= int(Item.Rarity.EPIC):
		bmat.emission_energy_multiplier = 3.4
	if int(item.rarity) >= int(Item.Rarity.LEGENDARY):
		bmat.emission_energy_multiplier = 4.4
		cyl.top_radius = 0.22
		cyl.bottom_radius = 0.38
	_beam.set_surface_override_material(0, bmat)


func _is_filtered_out() -> bool:
	if item == null:
		return false
	return int(item.rarity) < SaveSystem.loot_filter_min_rarity


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
	# Pickup magnetism — items inside `magnetism_radius` of the player slide
	# toward them at increasing speed. Filtered items don't magnetize.
	if not _is_filtered_out():
		if _player == null:
			var players := get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				_player = players[0]
		if _player:
			var to_player: Vector3 = (_player.global_position + Vector3(0, 0.6, 0)) - global_position
			var dist: float = to_player.length()
			if dist < magnetism_radius and dist > 0.05:
				# Ease in with proximity — pull is gentle at 3m, snappy at <1m
				var t: float = 1.0 - (dist / magnetism_radius)
				var step: float = magnetism_speed * t * delta
				global_position += to_player.normalized() * step
				_initial_y = global_position.y  # re-baseline so bob doesn't snap


func _on_body_entered(body: Node) -> void:
	if _picked_up or item == null:
		return
	if body == null or not body.is_in_group("player"):
		return
	if _is_filtered_out():
		return
	if body.has_method("get_inventory"):
		var inv = body.get_inventory()
		if inv and inv.add_item(item):
			_picked_up = true
			# set_deferred — physics is mid-iteration, can't mutate area state inline
			set_deferred("monitoring", false)
			set_deferred("monitorable", false)
			EventBus.show_floating_text.emit(
				"+ " + item.display_name,
				global_position + Vector3(0, 0.6, 0),
				item.get_rarity_color()
			)
			queue_free()
