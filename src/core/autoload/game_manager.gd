extends Node
## 游戏全局管理器

const SectData = preload("res://src/core/data/sect_data.gd")


var current_sect: Resource = null  # SectData
var game_initialized: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not game_initialized:
		call_deferred("_auto_init_game")


func _auto_init_game() -> void:
	if game_initialized:
		return
	GameSetup.setup_new_game("青云宗")


func start_new_game(sect_name: String) -> void:
	current_sect = SectData.new()
	current_sect.name = sect_name
	current_sect.rank = 9
	TimeManager.year = 1
	TimeManager.month = 1
	TimeManager.era = 0
	game_initialized = true
	EventBus.game_started.emit()


func load_game(path: String) -> void:
	var result = SaveManager.load_game(path)
	if result:
		current_sect = result
		current_sect.ensure_disciple_ids()
		game_initialized = true
		EventBus.game_loaded.emit()


func save_game(slot_name: String) -> bool:
	if not is_game_running():
		return false
	var ok = SaveManager.save_game(slot_name, current_sect)
	if ok:
		EventBus.game_saved.emit()
	return ok


func is_game_running() -> bool:
	return game_initialized and current_sect != null
