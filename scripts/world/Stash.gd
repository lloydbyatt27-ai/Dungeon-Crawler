extends StaticBody3D
## Big stash chest in HubTown. Walk close, press F to open StashUI.
## Stash items are shared across every character on this install.

@export var npc_name: String = "Vault"

@onready var prompt_label: Label3D = $PromptLabel
@onready var name_label: Label3D = $NameLabel
@onready var interact_area: Area3D = $InteractArea
@onready var lid: MeshInstance3D = $Lid
@onready var glow: OmniLight3D = $Glow

var _player_in_range: bool = false
var _t: float = 0.0

signal opened


func _ready() -> void:
	prompt_label.visible = false
	name_label.text = npc_name
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	add_to_group("stash")


func _process(delta: float) -> void:
	_t += delta
	if glow:
		glow.light_energy = 0.9 + 0.2 * sin(_t * 2.5)
	if _player_in_range and Input.is_action_just_pressed("interact"):
		opened.emit()


func _on_body_entered(body: Node) -> void:
	if body and body.is_in_group("player"):
		_player_in_range = true
		prompt_label.visible = true


func _on_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		_player_in_range = false
		prompt_label.visible = false
