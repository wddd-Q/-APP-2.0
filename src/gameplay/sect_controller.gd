extends Node
## 宗门控制器

const FacilityData = preload("res://src/core/data/facility_data.gd")


func build_facility(type: String) -> bool:
	var sect = GameManager.current_sect
	if not sect or not sect.can_build():
		return false

	var template = DataRegistry.facility_templates.get(type, {})
	var cost = template.get("build_cost", {}).get(1, 0)

	if not sect.spend_spirit_stones(cost):
		return false

	var facility = FacilityData.new()
	facility.facility_type = type
	facility.level = 1
	facility.is_building = true
	facility.build_progress = 0
	sect.facilities.append(facility)

	EventBus.facility_built.emit(type, 1)
	EventBus.spirit_stones_changed.emit(sect.spirit_stones, -cost)
	return true


func upgrade_facility(type: String) -> bool:
	var sect = GameManager.current_sect
	var facility = sect.get_facility(type)
	if not facility or not facility.can_upgrade():
		return false

	var template = DataRegistry.facility_templates.get(facility.facility_type, {})
	var next_level = facility.level + 1
	var cost = template.get("build_cost", {}).get(next_level, 0)

	if not sect.spend_spirit_stones(cost):
		return false

	facility.level = next_level
	facility.is_building = true
	facility.build_progress = 35

	EventBus.facility_upgraded.emit(type, next_level)
	EventBus.spirit_stones_changed.emit(sect.spirit_stones, -cost)
	return true


func process_construction() -> void:
	var sect = GameManager.current_sect
	if not sect:
		return
	var changed = false
	for facility in sect.facilities:
		if not facility.is_building:
			continue
		facility.build_progress = mini(100, int(facility.build_progress) + 50)
		changed = true
		if facility.build_progress >= 100:
			facility.is_building = false
			facility.build_progress = 100
			EventBus.facility_upgraded.emit(facility.facility_type, facility.level)
	if changed:
		EventBus.facility_built.emit("", 0)


func check_rank_promotion() -> bool:
	var sect = GameManager.current_sect
	if not sect:
		return false

	var conditions = _get_rank_conditions(sect.rank - 1)
	if _meets_conditions(sect, conditions):
		var old_rank = sect.rank
		sect.rank -= 1
		EventBus.sect_rank_changed.emit(old_rank, sect.rank)
		return true
	return false


func set_decree(decree_id: String) -> void:
	var sect = GameManager.current_sect
	if not sect:
		return

	# 最多2条同时生效
	if sect.active_decrees.size() >= 2:
		sect.active_decrees.pop_front()
	sect.active_decrees.append(decree_id)


func remove_decree(decree_id: String) -> void:
	var sect = GameManager.current_sect
	if not sect:
		return
	sect.active_decrees.erase(decree_id)


func assign_position(disciple: Resource, position_name: String) -> bool:
	var sect = GameManager.current_sect
	if not sect or not disciple:
		return false

	var pos_data = DataRegistry.sect_positions.get(position_name, {})
	if pos_data.is_empty():
		return false
	if disciple.position == position_name:
		return true

	# 检查硬限制
	if disciple.realm < pos_data.get("min_realm", 0):
		return false

	# 检查宗门等级解锁
	if sect.rank > pos_data.get("rank_unlock", 9):
		return false

	# 检查该职位是否还有空位
	if not _has_position_slot(position_name):
		return false

	var old_pos = disciple.position
	disciple.position = position_name
	disciple.add_memory("宗门历%d年 被任命为%s。" % [TimeManager.year, position_name])
	EventBus.position_changed.emit(disciple.disciple_id, old_pos, position_name)
	return true


func can_assign_position(disciple: Resource, position_name: String) -> Dictionary:
	var sect = GameManager.current_sect
	if not sect or not disciple:
		return {"ok": false, "reason": "宗门或弟子不存在"}
	var pos_data = DataRegistry.sect_positions.get(position_name, {})
	if pos_data.is_empty():
		return {"ok": false, "reason": "职位不存在"}
	if disciple.position == position_name:
		return {"ok": true, "reason": "当前职位"}
	if disciple.realm < pos_data.get("min_realm", 0):
		return {"ok": false, "reason": "境界不足，需要%s" % DataRegistry.get_realm_name(pos_data.get("min_realm", 1))}
	if sect.rank > pos_data.get("rank_unlock", 9):
		return {"ok": false, "reason": "宗门品级不足，需要%d品" % pos_data.get("rank_unlock", 9)}
	if not _has_position_slot(position_name):
		return {"ok": false, "reason": "职位名额已满"}
	return {"ok": true, "reason": "可任命"}


func demote_to_default(disciple: Resource) -> void:
	if not disciple:
		return
	var old = disciple.position
	disciple.position = "普通弟子"
	EventBus.position_changed.emit(disciple.disciple_id, old, "普通弟子")


func get_position_count(position_name: String) -> int:
	var sect = GameManager.current_sect
	if not sect:
		return 0
	var count = 0
	for d in sect.disciples:
		if d.alive and d.position == position_name:
			count += 1
	return count


func get_position_max(position_name: String) -> int:
	var sect = GameManager.current_sect
	if not sect:
		return 0
	var pos_data = DataRegistry.sect_positions.get(position_name, {})
	if pos_data.is_empty():
		return 0
	var base_max = pos_data.get("max_count", 1)
	# 宗门等级每晋升一级，职位上限+1
	var rank_bonus = maxi(0, 9 - sect.rank)
	return base_max + rank_bonus


func _has_position_slot(position_name: String) -> bool:
	if position_name == "普通弟子":
		return true
	return get_position_count(position_name) < get_position_max(position_name)


func get_position_salary(position_name: String) -> int:
	return DataRegistry.sect_positions.get(position_name, {}).get("salary", 0)


func process_all_salaries() -> int:
	"""每月发放职位俸禄，返回总支出"""
	var sect = GameManager.current_sect
	if not sect:
		return 0

	var total = 0
	for d in sect.disciples:
		if not d.alive:
			continue
		var salary = get_position_salary(d.position)
		if salary > 0:
			if sect.spend_spirit_stones(salary):
				total += salary

	EventBus.spirit_stones_changed.emit(sect.spirit_stones, -total)
	return total


func _get_rank_conditions(target_rank: int) -> Dictionary:
	var conditions = {
		8: {"spirit_stones": 500, "min_disciples": 10},
		7: {"spirit_stones": 2000, "min_realm": 3, "min_count": 1},
		6: {"spirit_stones": 5000, "min_realm": 3, "min_count": 3, "prestige": 500},
		5: {"spirit_stones": 10000, "min_realm": 4, "min_count": 1},
		4: {"spirit_stones": 20000, "min_realm": 4, "min_count": 3, "prestige": 2000},
		3: {"spirit_stones": 50000, "min_realm": 5, "min_count": 1, "prestige": 5000},
		2: {"spirit_stones": 100000, "min_realm": 5, "min_count": 2, "prestige": 10000},
		1: {"spirit_stones": 500000, "min_realm": 6, "min_count": 1, "prestige": 50000},
	}
	return conditions.get(target_rank, {})


func _meets_conditions(sect: Resource, conditions: Dictionary) -> bool:
	if conditions.has("spirit_stones") and sect.spirit_stones < conditions["spirit_stones"]:
		return false
	if conditions.has("prestige") and sect.prestige < conditions["prestige"]:
		return false
	if conditions.has("min_disciples") and sect.disciples.size() < conditions["min_disciples"]:
		return false
	if conditions.has("min_realm"):
		var count = 0
		for d in sect.disciples:
			if d.realm >= conditions["min_realm"]:
				count += 1
		if count < conditions.get("min_count", 1):
			return false
	return true
