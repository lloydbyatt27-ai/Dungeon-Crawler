extends Control
## Top-down minimap rendered via _draw(). Reads the dungeon layout from
## DungeonGenerator and tracks player position + enemies + chests + boss.
## Press M to toggle a larger full-screen view.
##
## Coordinate mapping: world (x, z) → screen (x, z) so that world -Z (away
## from the camera, "north") points up on the minimap. The map is centered
## on the player's current position.

@export var compact_size: Vector2 = Vector2(240, 280)
@export var full_size: Vector2 = Vector2(820, 620)
@export var compact_scale: float = 3.0   # world units → pixels
@export var full_scale: float = 6.0

@export_group("Colors")
@export var bg_color: Color = Color(0, 0, 0, 0.55)
@export var border_color: Color = Color(0.7, 0.7, 0.8, 0.7)
@export var room_unseen_color: Color = Color(0.18, 0.18, 0.22, 0.35)
@export var room_seen_color: Color = Color(0.55, 0.55, 0.60, 0.55)
@export var room_boss_color: Color = Color(0.55, 0.25, 0.20, 0.65)
@export var room_treasure_color: Color = Color(0.55, 0.50, 0.20, 0.65)
@export var room_outline_color: Color = Color(0.85, 0.85, 0.90, 0.8)
@export var player_color: Color = Color(1.0, 0.85, 0.30)
@export var enemy_color: Color = Color(1.0, 0.35, 0.30)
@export var boss_marker_color: Color = Color(1.0, 0.15, 0.10)
@export var chest_color: Color = Color(1.0, 0.85, 0.30)

var _generator: Node = null
var _player: Node3D = null
var _explored: Dictionary = {}  # room_index → bool
var _is_full: bool = false


func _ready() -> void:
	custom_minimum_size = compact_size
	_apply_compact_layout()
	# Defer bind so the dungeon generator has time to finish _ready
	await get_tree().process_frame
	_bind()
	# Toggle action is wired on the parent CanvasLayer; we listen here too
	set_process_unhandled_input(true)


func _bind() -> void:
	var gens := get_tree().get_nodes_in_group("dungeon_generator")
	if not gens.is_empty():
		_generator = gens[0]
		if _generator.has_signal("generation_complete"):
			_generator.generation_complete.connect(_on_generation_complete)
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]


func _on_generation_complete(_pos: Vector3) -> void:
	queue_redraw()


func _process(_delta: float) -> void:
	# Late-bind in case the generator wasn't ready when we tried before
	if _generator == null:
		var gens := get_tree().get_nodes_in_group("dungeon_generator")
		if not gens.is_empty():
			_generator = gens[0]
	if _player == null:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			_player = players[0]
	_update_exploration()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map"):
		toggle_full()


func toggle_full() -> void:
	_is_full = not _is_full
	if _is_full:
		_apply_full_layout()
	else:
		_apply_compact_layout()


func _apply_compact_layout() -> void:
	custom_minimum_size = compact_size
	size = compact_size
	anchor_left = 1.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 0.0
	position = Vector2(-compact_size.x - 20.0, 230.0)


func _apply_full_layout() -> void:
	custom_minimum_size = full_size
	size = full_size
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	position = -full_size * 0.5


func _update_exploration() -> void:
	if _generator == null or _player == null:
		return
	var rooms = _generator.generated_rooms
	for i in range(rooms.size()):
		if _explored.get(i, false):
			continue
		var room = rooms[i]
		var c: Vector3 = room.center
		var s: Vector2 = room.size
		var pp: Vector3 = _player.global_position
		if abs(pp.x - c.x) <= s.x * 0.5 and abs(pp.z - c.z) <= s.y * 0.5:
			_explored[i] = true


func _draw() -> void:
	# Backdrop + border
	draw_rect(Rect2(Vector2.ZERO, size), bg_color, true)
	draw_rect(Rect2(Vector2.ZERO, size), border_color, false, 2.0)

	if _generator == null:
		return
	var rooms = _generator.generated_rooms
	if rooms.is_empty():
		return

	var scale_f: float = full_scale if _is_full else compact_scale
	var center := size * 0.5
	var player_xz := Vector2.ZERO
	if _player:
		player_xz = Vector2(_player.global_position.x, _player.global_position.z)

	# Clip drawing to the panel rect so rooms outside the view don't leak
	# beyond the border.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Rooms
	for i in range(rooms.size()):
		var room = rooms[i]
		var center3: Vector3 = room.center
		var room_size_v: Vector2 = room.size
		var room_xz := Vector2(center3.x, center3.z)
		var rel := (room_xz - player_xz) * scale_f
		var room_size_px: Vector2 = room_size_v * scale_f
		var rect_pos: Vector2 = center + rel - room_size_px * 0.5
		var room_rect := Rect2(rect_pos, room_size_px)

		# Cull rooms entirely outside the panel
		if not _rect_intersects(room_rect, Rect2(Vector2.ZERO, size)):
			continue

		var fill: Color = room_unseen_color
		if _explored.get(i, false):
			match str(room.type):
				"boss":     fill = room_boss_color
				"treasure": fill = room_treasure_color
				_:          fill = room_seen_color
		draw_rect(room_rect, fill, true)
		if _explored.get(i, false):
			draw_rect(room_rect, room_outline_color, false, 1.5)

	# Chests
	var chests := get_tree().get_nodes_in_group("interactable")
	for chest in chests:
		if not (chest is Node3D):
			continue
		var pos := _world_to_map(chest.global_position, player_xz, scale_f, center)
		if not _in_panel(pos):
			continue
		_draw_diamond(pos, 4.0, chest_color)

	# Enemies (only if their room is explored — simulates line-of-sight)
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not (enemy is Node3D):
			continue
		if "health" in enemy and enemy.health and enemy.health.is_dead:
			continue
		var pos := _world_to_map(enemy.global_position, player_xz, scale_f, center)
		if not _in_panel(pos):
			continue
		var room_idx := _find_room_index_for_position(enemy.global_position, rooms)
		if room_idx == -1 or not _explored.get(room_idx, false):
			continue
		var is_boss := enemy.is_in_group("boss")
		if is_boss:
			_draw_triangle(pos, 6.5, boss_marker_color)
		else:
			draw_circle(pos, 2.6, enemy_color)

	# Player marker — always on top, always in the center
	draw_circle(center, 4.0, player_color)
	if _player:
		var facing_3d: Vector3 = -_player.global_transform.basis.z
		var facing_2d := Vector2(facing_3d.x, facing_3d.z)
		if facing_2d.length() > 0.01:
			facing_2d = facing_2d.normalized() * 11.0
			draw_line(center, center + facing_2d, player_color, 2.0, true)

	# Legend (compact mode only)
	if not _is_full:
		var label_y: float = size.y - 16.0
		draw_string(ThemeDB.fallback_font, Vector2(8, label_y), "[M] Map",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.85, 0.85, 0.85))


# --- helpers --------------------------------------------------------

func _world_to_map(world: Vector3, player_xz: Vector2, scale_f: float, center: Vector2) -> Vector2:
	return center + (Vector2(world.x, world.z) - player_xz) * scale_f


func _in_panel(p: Vector2) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x <= size.x and p.y <= size.y


func _rect_intersects(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b)


func _find_room_index_for_position(pos: Vector3, rooms: Array) -> int:
	for i in range(rooms.size()):
		var r = rooms[i]
		var c: Vector3 = r.center
		var s: Vector2 = r.size
		if abs(pos.x - c.x) <= s.x * 0.5 + 0.5 and abs(pos.z - c.z) <= s.y * 0.5 + 0.5:
			return i
	return -1


func _draw_diamond(pos: Vector2, half: float, color: Color) -> void:
	var pts := PackedVector2Array([
		pos + Vector2(0, -half),
		pos + Vector2(half, 0),
		pos + Vector2(0, half),
		pos + Vector2(-half, 0),
	])
	draw_colored_polygon(pts, color)


func _draw_triangle(pos: Vector2, half: float, color: Color) -> void:
	var pts := PackedVector2Array([
		pos + Vector2(0, -half),
		pos + Vector2(half, half * 0.85),
		pos + Vector2(-half, half * 0.85),
	])
	draw_colored_polygon(pts, color)
