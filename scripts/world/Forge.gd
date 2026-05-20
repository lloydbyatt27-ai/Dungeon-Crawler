extends StaticBody3D
## Forge NPC — spends Soul Shards to upgrade an item (+25% to stats each level,
## max +5). Walk close, press F to open ForgeUI.

@export var npc_name: String = "Forgemaster"

@onready var prompt_label: Label3D = $PromptLabel
@onready var name_label: Label3D = $NameLabel
@onready var interact_area: Area3D = $InteractArea
@onready var orb: MeshInstance3D = $Anvil/Orb
@onready var orb_light: OmniLight3D = $Anvil/OrbLight

var _player_in_range: bool = false
var _t: float = 0.0

signal opened


func _ready() -> void:
	prompt_label.visible = false
	name_label.text = npc_name
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	add_to_group("forge")


func _process(delta: float) -> void:
	_t += delta
	if orb:
		orb.rotate_y(delta * 1.4)
		orb.position.y = 0.9 + sin(_t * 2.5) * 0.06
	if orb_light:
		orb_light.light_energy = 1.4 + 0.3 * sin(_t * 3.0)
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
