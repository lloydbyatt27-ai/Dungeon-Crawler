class_name DungeonGenerator
extends Node3D
## Procedurally lays out a linear sequence of rooms along -Z and populates
## them with enemies, chests, and a boss. Each generation pulls from the
## ROOM_SPECS table, picks 3-5 mid-rooms from a weighted pool, and bookends
## with an entry and boss room.
##
## Geometry is built as StaticBody3D children of this node so the scene
## graph stays clean — clearing this node clears the whole dungeon.

@export var goblin_scene: PackedScene
@export var goblin_archer_scene: PackedScene
@export var skeleton_mage_scene: PackedScene
@export var orc_brute_scene: PackedScene
@export var goblin_chief_scene: PackedScene
@export var chest_scene: PackedScene
@export var wall_material: Material
@export var floor_material: Material
@export_group("Layout")
@export var seed: int = 0           # 0 = randomize each run
@export var min_mid_rooms: int = 3
@export var max_mid_rooms: int = 5
@export var door_width: float = 6.0
@export var wall_height: float = 3.0
@export var wall_thickness: float = 1.0

const ROOM_SPECS: Dictionary = {
	"entry": {
		"size": Vector2(20, 16),
		"enemies": 0,
		"is_entry": true,
		"light_color": Color(1.0, 0.85, 0.55),
		"light_energy": 1.2,
	},
	"combat_small": {
		"size": Vector2(20, 16),
		"enemies": 2,
		"light_color": Color(1.0, 0.85, 0.55),
		"light_energy": 0.9,
	},
	"combat_large": {
		"size": Vector2(26, 22),
		"enemies": 4,
		"light_color": Color(1.0, 0.85, 0.55),
		"light_energy": 1.0,
	},
	"treasure": {
		"size": Vector2(16, 14),
		"enemies": 1,
		"chest": true,
		"light_color": Color(1.0, 0.85, 0.4),
		"light_energy": 1.4,
	},
	"boss": {
		"size": Vector2(30, 26),
		"boss": true,
		"light_color": Color(1.0, 0.4, 0.2),
		"light_energy": 1.6,
	},
}

# Weighted pool for mid-room selection
const MID_POOL: Array = [
	{"id": "combat_small", "weight": 45},
	{"id": "combat_large", "weight": 35},
	{"id": "treasure",     "weight": 20},
]

signal generation_complete(player_spawn: Vector3)

var _rng: RandomNumberGenerator
var _player_spawn: Vector3 = Vector3.ZERO
var _generated_rooms: Array = []


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	if seed != 0:
		_rng.seed = seed
	else:
		_rng.randomize()
	_generate()
	# Defer entity placement one frame so all child _ready calls (player,
	# camera, HUD) have run before we move things around.
	await get_tree().process_frame
	_emit_complete()


func _generate() -> void:
	# Build the room sequence
	var sequence: Array[String] = ["entry"]
	var mid_count: int = _rng.randi_range(min_mid_rooms, max_mid_rooms)
	for _i in range(mid_count):
		sequence.append(_pick_mid_room())
	sequence.append("boss")

	# Lay out rooms along -Z. z_cursor is the boundary between the previous
	# room and the next — each new room extends from z_cursor to z_cursor - size.y.
	var z_cursor: float = 0.0
	for i in range(sequence.size()):
		var spec: Dictionary = ROOM_SPECS[sequence[i]].duplicate()
		# Slight size variation (each axis ±2 units) so rooms feel distinct
		var size: Vector2 = spec.size + Vector2(
			_rng.randi_range(-2, 2), _rng.randi_range(-1, 1)
		)
		# Don't shrink below the door width + margin
		size.x = max(size.x, door_width + 6.0)
		size.y = max(size.y, 10.0)
		spec.size = size

		var center_z: float = z_cursor - size.y * 0.5
		var center: Vector3 = Vector3(0, 0, center_z)

		_build_room(center, size, spec)
		_populate_room(center, size, spec)
		if spec.get("is_entry", false):
			_player_spawn = Vector3(0, 1.0, center_z + size.y * 0.30)

		# Build the dividing wall between this room and the next one
		if i < sequence.size() - 1:
			_build_divider(z_cursor - size.y, size.x)
		# Bookend walls (no doorway): north wall of entry, south wall of boss
		if i == 0:
			_build_wall_box(Vector3(0, wall_height * 0.5, z_cursor), Vector3(size.x, wall_height, wall_thickness))
		if i == sequence.size() - 1:
			_build_wall_box(Vector3(0, wall_height * 0.5, z_cursor - size.y), Vector3(size.x, wall_height, wall_thickness))

		_generated_rooms.append({"type": sequence[i], "center": center, "size": size})
		z_cursor -= size.y


func _pick_mid_room() -> String:
	var total := 0
	for entry in MID_POOL:
		total += int(entry.weight)
	var roll := _rng.randi_range(0, total - 1)
	var accum := 0
	for entry in MID_POOL:
		accum += int(entry.weight)
		if roll < accum:
			return entry.id
	return "combat_small"


# --- Geometry builders ---------------------------------------------

func _build_room(center: Vector3, size: Vector2, spec: Dictionary) -> void:
	# Floor
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	add_child(floor_body)
	floor_body.global_position = center

	var floor_mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	pm.subdivide_width = max(2, int(size.x / 3))
	pm.subdivide_depth = max(2, int(size.y / 3))
	floor_mesh.mesh = pm
	if floor_material:
		floor_mesh.set_surface_override_material(0, floor_material)
	floor_body.add_child(floor_mesh)

	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(size.x, 0.2, size.y)
	floor_shape.shape = floor_box
	floor_shape.position = Vector3(0, -0.1, 0)
	floor_body.add_child(floor_shape)

	# East and West walls
	_build_wall_box(
		center + Vector3(size.x * 0.5, wall_height * 0.5, 0),
		Vector3(wall_thickness, wall_height, size.y)
	)
	_build_wall_box(
		center + Vector3(-size.x * 0.5, wall_height * 0.5, 0),
		Vector3(wall_thickness, wall_height, size.y)
	)

	# Room light
	var light := OmniLight3D.new()
	light.position = center + Vector3(0, 3.5, 0)
	light.light_color = spec.get("light_color", Color(1, 0.85, 0.55))
	light.light_energy = spec.get("light_energy", 1.0)
	light.omni_range = max(size.x, size.y) * 0.7
	add_child(light)


func _build_wall_box(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	body.global_position = center

	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	if wall_material:
		mesh.set_surface_override_material(0, wall_material)
	body.add_child(mesh)

	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)


func _build_divider(z: float, room_width: float) -> void:
	# Internal wall at z with a centered doorway gap of door_width
	var seg_length: float = (room_width - door_width) * 0.5
	if seg_length <= 0.1:
		return
	# Left segment
	_build_wall_box(
		Vector3(-(door_width * 0.5 + seg_length * 0.5), wall_height * 0.5, z),
		Vector3(seg_length, wall_height, wall_thickness)
	)
	# Right segment
	_build_wall_box(
		Vector3(door_width * 0.5 + seg_length * 0.5, wall_height * 0.5, z),
		Vector3(seg_length, wall_height, wall_thickness)
	)


# --- Entity population ----------------------------------------------

func _populate_room(center: Vector3, size: Vector2, spec: Dictionary) -> void:
	# Enemies — rolled from a weighted pool so rooms mix archetypes
	var n_enemies: int = spec.get("enemies", 0)
	for j in range(n_enemies):
		var enemy_scene := _pick_enemy_scene()
		if enemy_scene == null:
			break
		var enemy := enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = center + Vector3(
			_rng.randf_range(-size.x * 0.35, size.x * 0.35),
			0.0,
			_rng.randf_range(-size.y * 0.35, size.y * 0.35)
		)
	# Boss
	if spec.get("boss", false) and goblin_chief_scene:
		var boss := goblin_chief_scene.instantiate()
		add_child(boss)
		boss.global_position = center + Vector3(0, 0, -size.y * 0.25)
	# Chest
	if spec.get("chest", false) and chest_scene:
		var chest := chest_scene.instantiate()
		add_child(chest)
		chest.global_position = center + Vector3(
			_rng.randf_range(-size.x * 0.15, size.x * 0.15),
			0.0,
			_rng.randf_range(-size.y * 0.15, size.y * 0.15)
		)


# Weighted pool of enemy scenes for combat rooms.
func _pick_enemy_scene() -> PackedScene:
	var pool: Array = []
	if goblin_scene:        pool.append({"scene": goblin_scene,        "weight": 50})
	if goblin_archer_scene: pool.append({"scene": goblin_archer_scene, "weight": 25})
	if skeleton_mage_scene: pool.append({"scene": skeleton_mage_scene, "weight": 15})
	if orc_brute_scene:     pool.append({"scene": orc_brute_scene,     "weight": 10})
	if pool.is_empty():
		return null
	var total := 0
	for e in pool:
		total += int(e.weight)
	var roll := _rng.randi_range(0, total - 1)
	var accum := 0
	for e in pool:
		accum += int(e.weight)
		if roll < accum:
			return e.scene
	return pool[0].scene


# --- Finalize -------------------------------------------------------

func _emit_complete() -> void:
	# Move the player to the entry spawn point
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var p := players[0] as Node3D
		if p:
			p.global_position = _player_spawn
	generation_complete.emit(_player_spawn)


func get_room_count() -> int:
	return _generated_rooms.size()
