class_name DungeonData
extends Resource
## 副本秘境实例数据

@export var dungeon_id: String = ""
@export var dungeon_name: String = ""
@export var dungeon_type: String = ""  # "secret_realm" | "ancient_ruin" | "beast_lair" | "demon_cave" | "mine"
@export var difficulty: int = 1
@export var danger_level: int = 30
@export var region_id: String = ""
@export var exploration_months: int = 2
@export var min_disciple_realm: int = 1
@export var min_disciple_count: int = 1
@export var max_disciple_count: int = 3
@export var is_discovered: bool = false
@export var on_cooldown: int = 0
@export var cooldown_duration: int = 6
@export var description: String = ""
@export var loot_pool: Array = []
@export var event_pool: Array = []
@export var active_expedition: Dictionary = {}


func is_available() -> bool:
	return is_discovered and on_cooldown <= 0 and active_expedition.is_empty()


func start_expedition(disciple_ids: Array, allied_faction: String, start_month: int) -> void:
	active_expedition = {
		"disciple_ids": disciple_ids,
		"allied_faction": allied_faction,
		"start_month": start_month,
		"complete_month": start_month + exploration_months,
	}


func clear_expedition() -> void:
	active_expedition = {}
	on_cooldown = cooldown_duration
