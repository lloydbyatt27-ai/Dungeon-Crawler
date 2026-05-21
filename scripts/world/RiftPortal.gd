extends StaticBody3D
## Greater Rift portal. Enters a single dungeon scaled by the chosen rift
## tier; the player has a timer to defeat the boss for a new tier record.
##
## Tier scaling lives in DungeonGenerator (HP/damage/xp multipliers). The
## HUD reads SaveSystem.rift_active and counts down rift_time_remaining.

@export var dungeon_path: String = "res://scenes/world/ProceduralDungeon.tscn"
@export var base_seconds: float = 240.0  # 4 minutes baseline per attempt

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
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	await get_tree().process_frame
	_refresh_subtitle()


func _refresh_subtitle() -> void:
	var best := SaveSystem.rift_best_tier
	var next_tier := max(1, best + 1)
	if best > 0:
		subtitle_label.text = "Best: T%d   ·   Next: T%d" % [best, next_tier]
	else:
		subtitle_label.text = "First attempt: T1"


func _process(delta: float) -> void:
	_t += delta
	if beam:
		beam.rotate_y(delta * 1.2)
		var pulse: float = 1.0 + 0.15 * sin(_t * 4.0)
		beam.scale = Vector3(pulse, 1.0, pulse)
	if portal_light:
		portal_light.light_energy = 1.8 + 0.6 * sin(_t * 4.5)
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
	# Flag rift mode and set the timer/tier
	SaveSystem.rift_active = true
	SaveSystem.rift_tier = max(1, SaveSystem.rift_best_tier + 1)
	SaveSystem.rift_time_remaining = base_seconds
	SaveSystem.endless_mode = false
	GameState.run_stats = {
		"monsters_killed": 0, "bosses_defeated": 0, "deaths": 0,
		"gold_earned_total": 0, "items_collected": 0,
		"play_time_seconds": 0.0, "dungeons_completed": 0,
	}
	var tween := create_tween()
	tween.tween_property(beam, "scale", Vector3(2.6, 2.6, 2.6), 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file(dungeon_path))
