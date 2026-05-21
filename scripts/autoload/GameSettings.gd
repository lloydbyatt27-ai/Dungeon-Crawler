extends Node
## Display and camera settings. Persisted to user://display_settings.json.
## Applied to the running scene on _ready and on every setter call.

const FILE_PATH: String = "user://display_settings.json"

# --- Persisted fields ---
var fullscreen: bool = false
var vsync: bool = true
var max_fps: int = 60               # 0 = uncapped
var camera_zoom: float = 16.0       # IsometricCamera.size
var screen_shake_scale: float = 1.0 # multiplier on requested shake strength
var damage_numbers_enabled: bool = true

const FPS_OPTIONS: Array = [30, 60, 120, 144, 240, 0]


func _ready() -> void:
	_load()
	_apply_all()


# --- Setters (apply + save) ---

func set_fullscreen(v: bool) -> void:
	fullscreen = v
	_apply_window_mode()
	_save()


func set_vsync(v: bool) -> void:
	vsync = v
	_apply_vsync()
	_save()


func set_max_fps(v: int) -> void:
	max_fps = max(0, v)
	Engine.max_fps = max_fps
	_save()


func set_camera_zoom(v: float) -> void:
	camera_zoom = clamp(v, 8.0, 28.0)
	_apply_camera_zoom()
	_save()


func set_screen_shake_scale(v: float) -> void:
	screen_shake_scale = clamp(v, 0.0, 2.0)
	_save()


func set_damage_numbers_enabled(v: bool) -> void:
	damage_numbers_enabled = v
	_save()


# --- Apply helpers ---

func _apply_all() -> void:
	_apply_window_mode()
	_apply_vsync()
	Engine.max_fps = max_fps
	_apply_camera_zoom()


func _apply_window_mode() -> void:
	var mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _apply_vsync() -> void:
	var mode: int = DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)


func _apply_camera_zoom() -> void:
	# Find the active IsometricCamera and update its orthographic size.
	var cam := get_tree().current_scene.get_viewport().get_camera_3d() if get_tree().current_scene else null
	if cam and cam is Camera3D:
		(cam as Camera3D).size = camera_zoom


# --- Persistence ---

func _load() -> void:
	if not FileAccess.file_exists(FILE_PATH):
		return
	var f := FileAccess.open(FILE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		fullscreen = bool(parsed.get("fullscreen", false))
		vsync = bool(parsed.get("vsync", true))
		max_fps = int(parsed.get("max_fps", 60))
		camera_zoom = float(parsed.get("camera_zoom", 16.0))
		screen_shake_scale = float(parsed.get("screen_shake_scale", 1.0))
		damage_numbers_enabled = bool(parsed.get("damage_numbers_enabled", true))


func _save() -> void:
	var data: Dictionary = {
		"fullscreen": fullscreen,
		"vsync": vsync,
		"max_fps": max_fps,
		"camera_zoom": camera_zoom,
		"screen_shake_scale": screen_shake_scale,
		"damage_numbers_enabled": damage_numbers_enabled,
	}
	var f := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
