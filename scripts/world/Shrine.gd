extends StaticBody3D
## Walk close, press F to drink. Restores HP and Mana to full, grants a
## brief damage_bonus buff. One-shot per dungeon.

@export var damage_buff_duration: float = 25.0
@export var damage_buff_amount: float = 0.20

@onready var orb: MeshInstance3D = $Orb
@onready var orb_light: OmniLight3D = $OrbLight
@onready var prompt_label: Label3D = $PromptLabel
@onready var interact_area: Area3D = $InteractArea

var _used: bool = false
var _player_in_range: bool = false
var _bob_t: float = 0.0


func _ready() -> void:
	prompt_label.visible = false
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if _used:
		return
	# Orb bob + slow spin
	_bob_t += delta
	orb.position.y = 1.4 + sin(_bob_t * 2.0) * 0.07
	orb.rotate_y(delta * 0.8)

	if _player_in_range and Input.is_action_just_pressed("interact"):
		_activate()


func _on_body_entered(body: Node) -> void:
	if _used:
		return
	if body and body.is_in_group("player"):
		_player_in_range = true
		prompt_label.visible = true


func _on_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		_player_in_range = false
		prompt_label.visible = false


func _activate() -> void:
	_used = true
	prompt_label.visible = false
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	# Full heal + mana
	if player.health:
		player.health.heal(player.health.max_health)
	if player.stats:
		player.current_mana = player.stats.max_mana()
	# Small temporary damage buff via SkillSystem's buff system
	if player.skill_system:
		player.skill_system.active_buff_amounts["damage_bonus"] = damage_buff_amount
		player.skill_system.active_buff_timers["damage_bonus"] = damage_buff_duration

	EventBus.show_floating_text.emit(
		"RESTORED",
		player.global_position + Vector3(0, 2.4, 0),
		Color(0.6, 1.0, 0.85)
	)

	# Visual: orb fades and dims
	var tween := create_tween()
	tween.tween_property(orb, "scale", Vector3(0.05, 0.05, 0.05), 0.6).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(orb_light, "light_energy", 0.0, 0.6)
