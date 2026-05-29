extends Node
## 前期目标控制器：用掌门初任目标帮助玩家理解核心玩法和故事入口。


var objectives: Array[Dictionary] = []
var story_unlocked: bool = false
var unread_updates: int = 0


func _ready() -> void:
	EventBus.game_started.connect(reset_for_new_game)
	EventBus.game_loaded.connect(_refresh_progress)
	EventBus.disciple_recruited.connect(func(_id: String): _complete_objective("recruit_disciple"))
	EventBus.facility_built.connect(func(_type: String, _level: int): _complete_objective("improve_facility"))
	EventBus.facility_upgraded.connect(func(_type: String, _level: int): _complete_objective("improve_facility"))
	EventBus.position_changed.connect(func(_id: String, _old_pos: String, new_pos: String):
		if new_pos != "普通弟子":
			_complete_objective("assign_officer")
	)
	EventBus.event_choice_made.connect(func(_event_id: String, _choice: int): _complete_objective("resolve_event"))


func reset_for_new_game() -> void:
	story_unlocked = false
	unread_updates = 0
	objectives = [
		{
			"id": "recruit_disciple",
			"title": "招收一名新弟子",
			"description": "发布招徒令，让宗门从初代三人之外开始扩张。",
			"hint": "打开弟子区域，点击「招收弟子 +」。",
			"completed": false,
		},
		{
			"id": "improve_facility",
			"title": "建设或升级一座设施",
			"description": "让山门从破败走向可经营的宗门。",
			"hint": "在宗门设施中选择建造或升级。",
			"completed": false,
		},
		{
			"id": "assign_officer",
			"title": "任命一名副长老或护法",
			"description": "让弟子承担管理职责，后续可委派处理宗门纪事。",
			"hint": "打开弟子详情，在职位下拉中任命。",
			"completed": false,
		},
		{
			"id": "resolve_event",
			"title": "处理一件宗门纪事",
			"description": "学习如何处理宗门消息，并观察后续影响。",
			"hint": "顶部红点出现后，打开「宗门纪事」选择方案并确认。",
			"completed": false,
		},
	]
	_refresh_progress()
	EventBus.onboarding_changed.emit()


func get_summary() -> Dictionary:
	var completed = 0
	for objective in objectives:
		if objective.get("completed", false):
			completed += 1
	return {
		"completed": completed,
		"total": objectives.size(),
		"story_unlocked": story_unlocked,
		"next": get_next_objective(),
	}


func get_next_objective() -> Dictionary:
	for objective in objectives:
		if not objective.get("completed", false):
			return objective
	return {}


func is_all_complete() -> bool:
	for objective in objectives:
		if not objective.get("completed", false):
			return false
	return not objectives.is_empty()


func mark_read() -> void:
	if unread_updates == 0:
		return
	unread_updates = 0
	EventBus.onboarding_changed.emit()


func serialize_state() -> Dictionary:
	return {
		"objectives": objectives,
		"story_unlocked": story_unlocked,
		"unread_updates": unread_updates,
	}


func restore_state(data: Dictionary) -> void:
	if data.is_empty():
		reset_for_new_game()
		return
	objectives = data.get("objectives", [])
	story_unlocked = data.get("story_unlocked", false)
	unread_updates = data.get("unread_updates", 0)
	_refresh_progress(false)
	EventBus.onboarding_changed.emit()


func _refresh_progress(count_updates: bool = false) -> void:
	var sect = GameManager.current_sect
	if not sect:
		return

	if sect.disciples.size() > 3:
		_complete_objective("recruit_disciple", count_updates)

	for facility in sect.facilities:
		if facility.level > 1:
			_complete_objective("improve_facility", count_updates)
			break
	if sect.facilities.size() > 2:
		_complete_objective("improve_facility", count_updates)

	for disciple in sect.disciples:
		if disciple.position != "普通弟子":
			_complete_objective("assign_officer", count_updates)
			break

	if EventController.event_records.size() > 0:
		_complete_objective("resolve_event", count_updates)

	_check_story_unlock(count_updates)


func _complete_objective(objective_id: String, count_update: bool = true) -> void:
	for objective in objectives:
		if objective.get("id", "") != objective_id:
			continue
		if objective.get("completed", false):
			return
		objective["completed"] = true
		if count_update:
			unread_updates += 1
		EventBus.onboarding_changed.emit()
		_check_story_unlock(count_update)
		return


func _check_story_unlock(count_update: bool = true) -> void:
	if story_unlocked or not is_all_complete():
		return
	story_unlocked = true
	if count_update:
		unread_updates += 1
	var sect = GameManager.current_sect
	if sect:
		sect.prestige += 20
		for disciple in sect.disciples:
			if disciple.alive:
				disciple.add_memory("宗门初任诸事渐定，山门旧阵基的传闻开始浮出水面。")
	EventBus.lore_unlocked.emit("onboarding:old_array")
	EventBus.onboarding_changed.emit()
