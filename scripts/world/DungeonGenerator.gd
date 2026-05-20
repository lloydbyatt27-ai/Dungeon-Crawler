class_name DungeonGenerator
extends Node3D
## Procedural dungeon generator. Builds a linear main chain (entry → 3-5 mid
## rooms → boss) and optionally attaches side branches (shrine / extra
## treasure / mini-boss) to mid-rooms. Each room declares which of its four
## sides have a doorway; walls are built segment-by-segment with gaps.

@export var goblin_scene: PackedScene
@export var goblin_archer_scene: PackedScene
@export var skeleton_mage_scene: PackedScene
@export var orc_brute_scene: PackedScene
@export var goblin_chief_scene: PackedScene
@export var chest_scene: PackedScene
@export var shrine_scene: PackedScene
@export var wall_material: Material
@export var floor_material: Material
@export_group("Layout")
@export var seed: int = 0
@export var min_mid_rooms: int = 3
@export var max_mid_rooms: int = 5
@export var door_width: float = 6.0
@export var wall_height: float = 3.0
@export var wall_thickness: float = 1.0
@export_range(0.0, 1.0) var side_branch_chance: float = 0.45

const ROOM_SPECS: Dictionary = {
	"entry":        {"size": Vector2(20, 16), "enemies": 0, "is_entry": true,
	                  "light_color": Color(1.0, 0.85, 0.55), "light_energy": 1.2},
	"combat_small": {"size": Vector2(20, 16), "enemies": 2,
	                  "light_color": Color(1.0, 0.85, 0.55), "light_energy": 0.9},
	"combat_large": {"size": Vector2(26, 22), "enemies": 4,
	                  "light_color": Color(1.0, 0.85, 0.55), "light_energy": 1.0},
	"treasure":     {"size": Vector2(16, 14), "enemies": 1, "chest": true,
	                  "light_color": Color(1.0, 0.85, 0.4),  "light_energy": 1.4},
	"boss":         {"size": Vector2(30, 26), "boss": true,
	                  "light_color": Color(1.0, 0.4, 0.2),   "light_energy": 1.6},
	# Side-branch types
	"shrine_room":     {"size": Vector2(14, 12), "enemies": 0, "shrine": true,
	                     "light_color": Color(0.7, 1.0, 0.85), "light_energy": 1.5},
	"extra_treasure":  {"size": Vector2(14, 12), "enemies": 1, "chest": true,
	                     "light_color": Color(1.0, 0.85, 0.4),  "light_energy": 1.5},
	"mini_boss":       {"size": Vector2(20, 16), "enemies": 0, "mini_boss": true,
	                     "light_color": Color(1.0, 0.45, 0.30), "light_energy": 1.3},
}

const MID_POOL: Array = [
	{"id": "combat_small", "weight": 45},
	{"id": "combat_large", "weight": 35},
	{"id": "treasure",     "weight": 20},
]

const SIDE_POOL: Array = [
	{"id": "shrine_room",    "weight": 35},
	{"id": "extra_treasure", "weight": 40},
	{"id": "mini_boss",      "weight": 25},
]

signal generation_complete(player_spawn: Vector3)

var _rng: RandomNumberGenerator
var _player_spawn: Vector3 = Vector3.ZERO
var generated_rooms: Array = []


func _ready() -> void:
	add_to_group("dungeon_generator")
	_rng = RandomNumberGenerator.new()
	if seed != 0:
		_rng.seed = seed
	else:
		_rng.randomize()
	_generate()
	AudioManager.play_music(AudioManager.dungeon_music)
	await get_tree().process_frame
	_emit_complete()


func _generate() -> void:
	_layout_main_chain()
	_layout_side_branches()
	# Build geometry for everything
	for room in generated_rooms:
		_build_room(room)
	# Populate
	for room in generated_rooms:
		_populate_room(room)


# --- Layout phase --------------------------------------------------

func _layout_main_chain() -> void:
	var sequence: Array[String] = ["entry"]
	var mid_count: int = _rng.randi_range(min_mid_rooms, max_mid_rooms)
	for _i in range(mid_count):
		sequence.append(_pick_from_pool(MID_POOL))
	sequence.append("boss")

	var z_cursor: float = 0.0
	for i in range(sequence.size()):
		var type_id: String = sequence[i]
		var spec: Dictionary = ROOM_SPECS[type_id]
		var base_size: Vector2 = spec.size
		var size: Vector2 = base_size + Vector2(_rng.randi_range(-2, 2), _rng.randi_range(-1, 1))
		size.x = max(size.x, door_width + 6.0)
		size.y = max(size.y, 10.0)
		var center := Vector3(0, 0, z_cursor - size.y * 0.5)
		var doors: Array = []
		if i > 0:
			doors.append("north")
		if i < sequence.size() - 1:
			doors.append("south")
		var room := {
			"type": type_id,
			"center": center,
			"size": size,
			"doors": doors,
			"is_main": true,
		}
		generated_rooms.append(room)
		if spec.get("is_entry", false):
			_player_spawn = Vector3(0, 1.0, center.z + size.y * 0.30)
		z_cursor -= size.y


func _layout_side_branches() -> void:
	# Copy because we'll be appending to generated_rooms while iterating
	var candidates: Array = []
	for r in generated_rooms:
		if r.get("is_main", false) and r.type in ["combat_small", "combat_large", "treasure"]:
			candidates.append(r)
	for parent in candidates:
		if _rng.randf() >= side_branch_chance:
			continue
		var side_type: String = _pick_from_pool(SIDE_POOL)
		var spec: Dictionary = ROOM_SPECS[side_type]
		var base_size: Vector2 = spec.size
		var size: Vector2 = base_size + Vector2(_rng.randi_range(-1, 1), _rng.randi_range(-1, 1))
		size.x = max(size.x, door_width + 4.0)
		size.y = max(size.y, 8.0)
		var east_side: bool = _rng.randf() < 0.5
		var dx: float = (parent.size.x * 0.5 + size.x * 0.5) * (1.0 if east_side else -1.0)
		var center: Vector3 = parent.center + Vector3(dx, 0.0, 0.0)
		var doors: Array = ["west" if east_side else "east"]
		# Open the parent's wall on that side
		parent.doors.append("east" if east_side else "west")
		generated_rooms.append({
			"type": side_type,
			"center": center,
			"size": size,
			"doors": doors,
			"is_main": false,
		})


func _pick_from_pool(pool: Array) -> String:
	var total := 0
	for entry in pool:
		total += int(entry.weight)
	var roll := _rng.randi_range(0, total - 1)
	var accum := 0
	for entry in pool:
		accum += int(entry.weight)
		if roll < accum:
			return entry.id
	return pool[0].id


# --- Geometry phase ------------------------------------------------

func _build_room(room: Dictionary) -> void:
	var center: Vector3 = room.center
	var size: Vector2 = room.size
	var doors: Array = room.doors
	var spec: Dictionary = ROOM_SPECS.get(room.type, {})

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

	# Walls — one per side, gapped if the side has a doorway
	_build_wall_side(center, size, "north", "north" in doors)
	_build_wall_side(center, size, "south", "south" in doors)
	_build_wall_side(center, size, "east",  "east"  in doors)
	_build_wall_side(center, size, "west",  "west"  in doors)

	# Light
	var light := OmniLight3D.new()
	light.position = center + Vector3(0, 3.5, 0)
	light.light_color = spec.get("light_color", Color(1, 0.85, 0.55))
	light.light_energy = spec.get("light_energy", 1.0)
	light.omni_range = max(size.x, size.y) * 0.7
	add_child(light)


func _build_wall_side(center: Vector3, size: Vector2, side: String, has_door: bool) -> void:
	var hy: float = wall_height * 0.5
	match side:
		"north":
			var z: float = center.z - size.y * 0.5
			if has_door:
				_build_horiz_split(z, center.x, size.x, hy)
			else:
				_build_wall_box(Vector3(center.x, hy, z), Vector3(size.x, wall_height, wall_thickness))
		"south":
			var z2: float = center.z + size.y * 0.5
			if has_door:
				_build_horiz_split(z2, center.x, size.x, hy)
			else:
				_build_wall_box(Vector3(center.x, hy, z2), Vector3(size.x, wall_height, wall_thickness))
		"east":
			var x: float = center.x + size.x * 0.5
			if has_door:
				_build_vert_split(x, center.z, size.y, hy)
			else:
				_build_wall_box(Vector3(x, hy, center.z), Vector3(wall_thickness, wall_height, size.y))
		"west":
			var x2: float = center.x - size.x * 0.5
			if has_door:
				_build_vert_split(x2, center.z, size.y, hy)
			else:
				_build_wall_box(Vector3(x2, hy, center.z), Vector3(wall_thickness, wall_height, size.y))


func _build_horiz_split(z: float, x_center: float, length: float, hy: float) -> void:
	var seg: float = (length - door_width) * 0.5
	if seg <= 0.1:
		return
	_build_wall_box(
		Vector3(x_center - door_width * 0.5 - seg * 0.5, hy, z),
		Vector3(seg, wall_height, wall_thickness)
	)
	_build_wall_box(
		Vector3(x_center + door_width * 0.5 + seg * 0.5, hy, z),
		Vector3(seg, wall_height, wall_thickness)
	)


func _build_vert_split(x: float, z_center: float, length: float, hy: float) -> void:
	var seg: float = (length - door_width) * 0.5
	if seg <= 0.1:
		return
	_build_wall_box(
		Vector3(x, hy, z_center - door_width * 0.5 - seg * 0.5),
		Vector3(wall_thickness, wall_height, seg)
	)
	_build_wall_box(
		Vector3(x, hy, z_center + door_width * 0.5 + seg * 0.5),
		Vector3(wall_thickness, wall_height, seg)
	)


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


# --- Population ----------------------------------------------------

func _populate_room(room: Dictionary) -> void:
	var center: Vector3 = room.center
	var size: Vector2 = room.size
	var spec: Dictionary = ROOM_SPECS.get(room.type, {})

	# Regular enemies
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
		_apply_difficulty(enemy)
	# Boss
	if spec.get("boss", false) and goblin_chief_scene:
		var boss := goblin_chief_scene.instantiate()
		add_child(boss)
		boss.global_position = center + Vector3(0, 0, -size.y * 0.25)
		_apply_difficulty(boss)
	# Mini-boss (side branch) — beefier Orc Brute
	if spec.get("mini_boss", false) and orc_brute_scene:
		var brute := orc_brute_scene.instantiate()
		add_child(brute)
		brute.global_position = center
		# Make him bigger / scarier than a regular brute
		var brute_health = brute.get_node_or_null("Health")
		if brute_health:
			brute_health.max_health = 220.0
		if "attack_damage" in brute:
			brute.attack_damage = 26.0
		if "xp_value" in brute:
			brute.xp_value = 120
		_apply_difficulty(brute)
	# Chest
	if spec.get("chest", false) and chest_scene:
		var chest := chest_scene.instantiate()
		add_child(chest)
		chest.global_position = center + Vector3(
			_rng.randf_range(-size.x * 0.15, size.x * 0.15),
			0.0,
			_rng.randf_range(-size.y * 0.15, size.y * 0.15)
		)
	# Shrine
	if spec.get("shrine", false) and shrine_scene:
		var shrine := shrine_scene.instantiate()
		add_child(shrine)
		shrine.global_position = center


## Apply the current run's difficulty + endless-floor multipliers to an enemy.
## Called after add_child() so the enemy's _ready has set defaults.
func _apply_difficulty(enemy: Node) -> void:
	var data: Dictionary = DifficultyDatabase.get_data(SaveSystem.current_run_difficulty)
	# Endless-mode floor scaling: HP x 1.15^(floor-1), damage x 1.08^(floor-1),
	# xp x 1.10^(floor-1), gold x 1.05^(floor-1)
	var endless_hp_mult: float = 1.0
	var endless_dmg_mult: float = 1.0
	var endless_xp_mult: float = 1.0
	var endless_gold_mult: float = 1.0
	if SaveSystem.endless_mode and SaveSystem.current_endless_floor > 1:
		var f: int = SaveSystem.current_endless_floor - 1
		endless_hp_mult = pow(1.15, f)
		endless_dmg_mult = pow(1.08, f)
		endless_xp_mult = pow(1.10, f)
		endless_gold_mult = pow(1.05, f)

	var hp_node := enemy.get_node_or_null("Health") as Health
	if hp_node:
		hp_node.max_health *= float(data.get("hp_mult", 1.0)) * endless_hp_mult
		hp_node.current_health = hp_node.max_health
		hp_node.health_changed.emit(hp_node.current_health, hp_node.max_health)
	if "attack_damage" in enemy:
		enemy.attack_damage *= float(data.get("damage_mult", 1.0)) * endless_dmg_mult
	if "xp_value" in enemy:
		enemy.xp_value = int(float(enemy.xp_value) * float(data.get("xp_mult", 1.0)) * endless_xp_mult)
	if "gold_min" in enemy and "gold_max" in enemy:
		var gm: float = float(data.get("gold_mult", 1.0)) * endless_gold_mult
		enemy.gold_min = int(float(enemy.gold_min) * gm)
		enemy.gold_max = int(float(enemy.gold_max) * gm)
	if "essence_value" in enemy:
		enemy.essence_value *= float(data.get("essence_mult", 1.0))
	if "item_drop_chance" in enemy:
		enemy.item_drop_chance = min(1.0, float(enemy.item_drop_chance) + float(data.get("item_drop_bonus", 0.0)))


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


# --- Finalize ------------------------------------------------------

func _emit_complete() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var p := players[0] as Node3D
		if p:
			p.global_position = _player_spawn
	generation_complete.emit(_player_spawn)


func get_room_count() -> int:
	return generated_rooms.size()
