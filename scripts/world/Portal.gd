extends StaticBody3D
## Dungeon portal in the hub. Walk close, press F to enter a new dungeon.
## Saves the player first so progress carries.

@export var dungeon_path: String = "res://scenes/world/ProceduralDungeon.tscn"

@onready var prompt_label: Label3D = $PromptLabel
@onready var interact_area: Area3D = $InteractArea
@onready var beam: MeshInstance3D = $Beam
@onready var portal_light: OmniLight3D = $PortalLight

var _player_in_range: bool = false
var _entering: bool = false
var _t: float = 0.0


func _ready() -> void:
	prompt_label.visible = false
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	# Pulse the portal beam
	_t += delta
	beam.rotate_y(delta * 0.8)
	var pulse: float = 1.0 + 0.1 * sin(_t * 3.0)
	beam.scale = Vector3(pulse, 1.0, pulse)
	if portal_light:
		portal_light.light_energy = 1.6 + 0.4 * sin(_t * 4.0)

	if _player_in_range and not _entering and Input.is_action_just_pressed("interact"):
		_enter()


func _on_body_entered(body: Node) -> void:
	if body and body.is_in_group("player"):
		_player_in_range = true
		prompt_label.visible = true


func _on_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		_player_in_range = false
		prompt_label.visible = false


func _enter() -> void:
	_entering = true
	prompt_label.visible = false
	# Save before leaving so the hub state (gold, inventory) persists,
	# then reload it into pending_load_data so the dungeon scene's Player
	# picks it up on _ready.
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		SaveSystem.save_player(players[0])
		SaveSystem.load_save()
	# Reset run stats for the fresh dungeon
	GameState.run_stats = {
		"monsters_killed": 0, "bosses_defeated": 0, "deaths": 0,
		"gold_earned_total": 0, "items_collected": 0,
		"play_time_seconds": 0.0, "dungeons_completed": 0,
	}
	# A brief tween before scene change
	var tween := create_tween()
	tween.tween_property(beam, "scale", Vector3(2.0, 2.0, 2.0), 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file(dungeon_path))
