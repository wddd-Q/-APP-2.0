extends Node
## 时间管理器 — 以"月"为基本单位推进游戏时间


var month: int = 1   # 1-12
var year: int = 1    # 宗门历
var era: int = 0     # 纪元（用于大事件）
var is_paused: bool = false

var _accumulated_delta: float = 0.0
var _month_length: float = 3.0  # 每个月3秒实时（可调）


func _process(delta: float) -> void:
	if is_paused or not GameManager.game_initialized:
		return

	_accumulated_delta += delta
	if _accumulated_delta >= _month_length:
		_accumulated_delta -= _month_length
		advance_month()


func advance_month() -> void:
	month += 1
	if month > 12:
		month = 1
		year += 1
		EventBus.year_passed.emit(year)
		if year % 100 == 0:
			era += 1

	EventBus.month_passed.emit(month, year)


func advance_months(count: int) -> void:
	for i in range(count):
		advance_month()


func get_season() -> String:
	match month:
		1, 2, 3: return "春"
		4, 5, 6: return "夏"
		7, 8, 9: return "秋"
		_: return "冬"


func get_date_string() -> String:
	return "宗门历%d年 %s (%d月)" % [year, get_season(), month]


func set_speed(multiplier: float) -> void:
	_month_length = 3.0 / multiplier
