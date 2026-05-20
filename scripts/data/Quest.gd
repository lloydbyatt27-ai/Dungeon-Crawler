class_name Quest
extends RefCounted
## A single active quest instance. Created from a QuestDatabase template
## and lives in QuestSystem.active_quests while the player is working on it.

var id: String = ""
var title: String = ""
var description: String = ""
var objective_type: String = ""   # "kill", "find_rarity", "boss", "floor"
var target: int = 1               # how many to complete
var progress: int = 0
var target_rarity: int = 0        # for "find_rarity" objectives
var gold_reward: int = 0
var xp_reward: int = 0
var completed: bool = false


func progress_text() -> String:
	return "%d / %d" % [progress, target]


func progress_ratio() -> float:
	if target <= 0:
		return 1.0
	return clamp(float(progress) / float(target), 0.0, 1.0)
