extends Node
## Persistent key rebinding. Maintains a list of rebindable actions and
## stores any non-default keyboard binding in user://controls.json.
## On _ready: applies saved bindings to InputMap before any scene needs them.

const FILE_PATH: String = "user://controls.json"

# Actions exposed in the Controls UI. attack_light/heavy and the move
# axes intentionally not included — those should stay on mouse/WASD.
const REBINDABLE: Array = [
	"dodge",
	"skill_1", "skill_2", "skill_3",
	"shapeshift",
	"interact",
	"inventory",
	"quest_log",
	"toggle_map",
	"skill_tree",
]

# Friendly labels shown in the UI
const LABELS: Dictionary = {
	"dodge":       "Dodge",
	"skill_1":     "Skill 1",
	"skill_2":     "Skill 2",
	"skill_3":     "Skill 3",
	"shapeshift":  "Shapeshift",
	"interact":    "Interact",
	"inventory":   "Inventory",
	"quest_log":   "Quest Log",
	"toggle_map":  "Toggle Map",
	"skill_tree":  "Skills Panel",
}


func _ready() -> void:
	_load()


func _load() -> void:
	if not FileAccess.file_exists(FILE_PATH):
		return
	var f := FileAccess.open(FILE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return
	for action in parsed:
		var keycode: int = int(parsed[action])
		if keycode > 0:
			_apply_rebind(action, keycode)


func _save() -> void:
	var data: Dictionary = {}
	for action in REBINDABLE:
		var keycode := get_current_keycode(action)
		if keycode > 0:
			data[action] = keycode
	var f := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


## Returns the current keyboard physical_keycode for an action, or 0 if
## the action has no keyboard binding.
func get_current_keycode(action: String) -> int:
	if not InputMap.has_action(action):
		return 0
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).physical_keycode
	return 0


func get_current_key_text(action: String) -> String:
	var kc := get_current_keycode(action)
	if kc == 0:
		return "—"
	return OS.get_keycode_string(kc).to_upper()


## Reassigns the keyboard event for an action, preserving any non-keyboard
## events (gamepad bindings stay intact).
func rebind(action: String, new_keycode: int) -> void:
	_apply_rebind(action, new_keycode)
	_save()


func _apply_rebind(action: String, new_keycode: int) -> void:
	if not InputMap.has_action(action):
		return
	# Strip existing keyboard events
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	# Add the new one
	var ev := InputEventKey.new()
	ev.physical_keycode = new_keycode
	InputMap.action_add_event(action, ev)


## Restore all rebindable actions to whatever their project.godot defaults
## are by deleting the controls file and reloading from ProjectSettings.
func reset_to_defaults() -> void:
	if FileAccess.file_exists(FILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE_PATH))
	# InputMap.load_from_project_settings() re-reads the [input] section in
	# project.godot, replacing every action with its declared default events.
	InputMap.load_from_project_settings()
