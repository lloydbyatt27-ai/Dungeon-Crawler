extends StaticBody3D
## Walk close and press Interact (F) to open. Spawns 1-3 random items.
## One-shot: chest visually pops open and won't open again.

@export var min_items: int = 1
@export var max_items: int = 3
@export var item_pickup_scene: PackedScene
@export var gold_min: int = 30
@export var gold_max: int = 80
@export var gold_pickup_scene: PackedScene
@export var force_rare: bool = false  # if true, always rolls at least one rare+

@onready var lid: MeshInstance3D = $Lid
@onready var prompt_label: Label3D = $PromptLabel
@onready var interact_area: Area3D = $InteractArea

var _opened: bool = false
var _player_in_range: bool = false


func _ready() -> void:
	prompt_label.visible = false
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _opened or not _player_in_range:
		return
	if Input.is_action_just_pressed("interact"):
		_open()


func _on_body_entered(body: Node) -> void:
	if _opened:
		return
	if body and body.is_in_group("player"):
		_player_in_range = true
		prompt_label.visible = true


func _on_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		_player_in_range = false
		prompt_label.visible = false


func _open() -> void:
	_opened = true
	prompt_label.visible = false
	# Lid opens
	var tween := create_tween()
	tween.tween_property(lid, "rotation:x", deg_to_rad(-90.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Gold
	if gold_pickup_scene:
		var amount := randi_range(gold_min, gold_max)
		var pile := gold_pickup_scene.instantiate()
		get_tree().current_scene.add_child(pile)
		pile.amount = amount
		pile.global_position = global_position + Vector3(0, 0.8, 0)

	# Items
	if item_pickup_scene:
		var n := randi_range(min_items, max_items)
		for i in range(n):
			var item: Item
			if force_rare and i == 0:
				# Force a rare/legendary roll for the first item
				item = _roll_min_rare()
			else:
				item = ItemDatabase.generate_random_item(1)
			if item:
				var pickup := item_pickup_scene.instantiate()
				get_tree().current_scene.add_child(pickup)
				pickup.global_position = global_position + Vector3(
					randf_range(-0.6, 0.6), 0.8, randf_range(-0.6, 0.6)
				)
				pickup.setup(item)


func _roll_min_rare() -> Item:
	# Hacky way to guarantee at least Rare quality
	for _i in range(20):
		var item := ItemDatabase.generate_random_item(1)
		if item and item.rarity >= Item.Rarity.RARE:
			return item
	return ItemDatabase.generate_random_item(1)
