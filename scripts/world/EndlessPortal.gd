extends StaticBody3D
## Purple-tinted endless portal. Starts a run that loops floor-to-floor with
## scaling difficulty, ending on death (the character keeps everything they
## found and a best_endless_floor record is saved).

@export var dungeon_path: String = "res://scenes/world/ProceduralDungeon.tscn"

@onready var prompt_label: Label3D = $PromptLabel
@onready var subtitle_label: Label3D = $SubtitleLabel
@onready var interact_area: Area3D = $InteractArea
@onready var beam: MeshInstance3D = $Beam
@onready var portal_light: OmniLight3D = $PortalLight

var _player_in_range: bool = false
var _entering: bool = false
var _t: float = 0.0


func _ready() -> void:
	prompt_label.visible = false
	subtitle_label.visible = true
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	# Subtitle shows the player's best record once we have a save loaded
	await get_tree().process_frame
	_refresh_subtitle()


func _refresh_subtitle() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		subtitle_label.text = ""
		return
	var p = players[0]
	if p.stats and p.stats.best_endless_floor > 0:
		subtitle_label.text = "Best: Floor %d" % p.stats.best_endless_floor


func _process(delta: float) -> void:
	_t += delta
	beam.rotate_y(delta * -1.0)
	var pulse: float = 1.0 + 0.12 * sin(_t * 3.5)
	beam.scale = Vector3(pulse, 1.0, pulse)
	if portal_light:
		portal_light.light_energy = 1.6 + 0.5 * sin(_t * 5.0)
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
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		SaveSystem.save_player(players[0])
		SaveSystem.load_save()
	# Flag endless mode on the next dungeon
	SaveSystem.endless_mode = true
	SaveSystem.current_endless_floor = 1
	GameState.run_stats = {
		"monsters_killed": 0, "bosses_defeated": 0, "deaths": 0,
		"gold_earned_total": 0, "items_collected": 0,
		"play_time_seconds": 0.0, "dungeons_completed": 0,
	}
	var tween := create_tween()
	tween.tween_property(beam, "scale", Vector3(2.5, 2.5, 2.5), 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file(dungeon_path))
