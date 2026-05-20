extends Node
## Listens to EventBus signals and spawns floating world-space text:
##  - show_damage_number: hit numbers from combat
##  - show_floating_text: generic notices (level up, low mana, etc.)

@export var damage_number_scene: PackedScene


func _ready() -> void:
	EventBus.show_damage_number.connect(_on_show_damage_number)
	EventBus.show_floating_text.connect(_on_show_floating_text)


func _on_show_damage_number(amount: float, world_position: Vector3, is_crit: bool) -> void:
	if damage_number_scene == null:
		return
	var num := damage_number_scene.instantiate() as DamageNumber
	get_tree().current_scene.add_child(num)
	num.setup(amount, world_position, is_crit)


func _on_show_floating_text(text: String, world_position: Vector3, color: Color) -> void:
	if damage_number_scene == null:
		return
	var num := damage_number_scene.instantiate() as DamageNumber
	get_tree().current_scene.add_child(num)
	num.setup(0.0, world_position, false)
	num.text = text
	num.modulate = color
	num.pixel_size = 0.012
	num.rise_distance = 2.0
	num.lifetime = 1.5
