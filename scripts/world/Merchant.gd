extends StaticBody3D
## Hub-town merchant NPC. Walk close, press F to open the VendorUI.
## Generates a randomized stock that refreshes every visit.

@export var merchant_name: String = "Armorer"
@export var stock_size: int = 8
@export var item_level: int = 1
@export var item_filter: Array = []  # e.g. ["WEAPON"] or ["ARMOR", "OFFHAND"]

@onready var prompt_label: Label3D = $PromptLabel
@onready var name_label: Label3D = $NameLabel
@onready var interact_area: Area3D = $InteractArea

var stock: Array[Item] = []
var _player_in_range: bool = false

signal opened(merchant: Node)


func _ready() -> void:
	prompt_label.visible = false
	name_label.text = merchant_name
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	refresh_stock()


func refresh_stock() -> void:
	stock.clear()
	for _i in range(stock_size):
		var item := ItemDatabase.generate_random_item(item_level, item_filter)
		if item:
			stock.append(item)


func remove_item(item: Item) -> void:
	stock.erase(item)


func _process(_delta: float) -> void:
	if _player_in_range and Input.is_action_just_pressed("interact"):
		opened.emit(self)


func _on_body_entered(body: Node) -> void:
	if body and body.is_in_group("player"):
		_player_in_range = true
		prompt_label.visible = true


func _on_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		_player_in_range = false
		prompt_label.visible = false
