extends Node
## Global game state singleton.
## Holds active character reference, current zone, run statistics.
## Use sparingly — prefer EventBus signals for cross-system communication.

signal game_paused(is_paused: bool)
signal zone_changed(new_zone_id: String)

var current_character = null  # Will hold Character resource once defined
var current_zone_id: String = "test_arena"
var is_paused: bool = false

var run_stats: Dictionary = {
	"monsters_killed": 0,
	"bosses_defeated": 0,
	"deaths": 0,
	"gold_earned_total": 0,
	"items_collected": 0,
	"play_time_seconds": 0.0,
}


func _process(delta: float) -> void:
	if not is_paused:
		run_stats.play_time_seconds += delta


func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)


func change_zone(zone_id: String) -> void:
	current_zone_id = zone_id
	zone_changed.emit(zone_id)
