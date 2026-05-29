extends Node
## 弟子控制器

const DiscipleData = preload("res://src/core/data/disciple_data.gd")


func recruit_disciple(candidate_data: Dictionary) -> DiscipleData:
	var sect = GameManager.current_sect
	if not sect:
		return null

	var disciple = DiscipleData.new()
	disciple.disciple_name = candidate_data.get("name", "无名弟子")
	disciple.gender = candidate_data.get("gender", 0)
	disciple.age = candidate_data.get("age", 18)
	disciple.bone_structure = candidate_data.get("bone_structure", 50)
	disciple.comprehension = candidate_data.get("comprehension", 50)
	disciple.fortune = candidate_data.get("fortune", 50)
	disciple.mentality = candidate_data.get("mentality", 50)
	disciple.charm = candidate_data.get("charm", 50)
	disciple.talent = candidate_data.get("talent", 50)
	disciple.spirit_root_quality = candidate_data.get("root_quality", "true")
	disciple.spirit_elements = candidate_data.get("elements", [])
	disciple.realm = 1
	disciple.sub_realm = 1
	disciple.lifespan = DataRegistry.cultivation_realms[1]["lifespan"]

	sect.add_disciple(disciple)
	disciple.add_memory("宗门历%d年 %s拜入宗门。" % [TimeManager.year, disciple.disciple_name])
	EventBus.disciple_recruited.emit(disciple.disciple_id)
	return disciple


const TASK_COSTS: Dictionary = {
	"cultivating": 0,
	"alchemy": 10,
	"crafting": 10,
	"exploring": 20,
	"guarding": 0,
	"teaching": 0,
	"idle": 0,
	"market_work": 0,
	"herb_gathering": 0,
	"guard_caravan": 0,
	"beast_hunting": 0,
	"teach_wanderers": 0,
}

## 打工任务每月收入范围 [min, max] 和境界要求
const WORK_INCOME: Dictionary = {
	"market_work": {"name": "坊市打工", "min": 10, "max": 25, "min_realm": 1, "risk": 0.0},
	"herb_gathering": {"name": "采集灵草", "min": 15, "max": 30, "min_realm": 1, "risk": 0.05},
	"guard_caravan": {"name": "护送商队", "min": 30, "max": 50, "min_realm": 2, "risk": 0.15},
	"beast_hunting": {"name": "猎杀妖兽", "min": 25, "max": 60, "min_realm": 2, "risk": 0.25},
	"teach_wanderers": {"name": "教导散修", "min": 20, "max": 40, "min_realm": 3, "risk": 0.0},
}

## 打工收入受弟子属性加成
func get_work_income(disciple: DiscipleData, task_id: String) -> int:
	var info = WORK_INCOME.get(task_id, {})
	if info.is_empty():
		return 0
	var base = info["min"] + randi() % (info["max"] - info["min"] + 1)
	# 福缘加成: 每20点福缘多10%
	var fortune_bonus = 1.0 + (disciple.fortune / 20) * 0.1
	# 魅力加成 (坊市/教导): 每20点魅力多5%
	if task_id in ["market_work", "teach_wanderers"]:
		fortune_bonus += (disciple.charm / 20) * 0.05
	return int(base * fortune_bonus)


func assign_task(disciple: DiscipleData, task_id: String) -> bool:
	var sect = GameManager.current_sect
	var cost = TASK_COSTS.get(task_id, 0)

	# 如果任务相同，不重复扣费
	if disciple.assigned_task == task_id:
		return true

	# 打工任务：检查境界要求
	if task_id in WORK_INCOME:
		var info = WORK_INCOME[task_id]
		if disciple.realm < info["min_realm"]:
			return false

	# 切换任务时，只对一次性任务收费
	if task_id == "exploring":
		if not sect or not sect.spend_spirit_stones(cost):
			return false
		EventBus.spirit_stones_changed.emit(sect.spirit_stones, -cost)

	disciple.assigned_task = task_id
	EventBus.disciple_task_assigned.emit(disciple.disciple_id, task_id)
	return true


func process_cultivation(disciple: DiscipleData) -> float:
	"""处理一个月修炼，返回修为获取量"""
	var speed = disciple.get_cultivation_speed()

	# 设施加成
	var sect = GameManager.current_sect
	var chamber = sect.get_facility("cultivation_chamber")
	if chamber:
		var bonus = DataRegistry.facility_templates.get("cultivation_chamber", {}).get("cultivation_bonus", {}).get(chamber.level, 0.0)
		speed *= (1.0 + bonus)

	# 藏经阁加成
	var pavilion = sect.get_facility("scripture_pavilion")
	if pavilion:
		var comp_bonus = DataRegistry.facility_templates.get("scripture_pavilion", {}).get("comprehension_bonus", {}).get(pavilion.level, 0.0)
		speed *= (1.0 + comp_bonus)

	# 门规加成
	if "清修令" in sect.active_decrees:
		speed *= 1.15

	# 新增修为
	var progress_gain = speed * 0.01  # 每月进度增量
	disciple.cultivation_progress += progress_gain
	disciple.age += 1.0 / 12.0  # 每月老1/12岁

	# 检查衰老
	_check_aging(disciple)

	return progress_gain


func check_breakthrough(disciple: DiscipleData) -> Dictionary:
	"""检查是否可以突破，返回突破结果"""
	var realm_data = DataRegistry.cultivation_realms.get(disciple.realm, {})
	var sub_stages = realm_data.get("sub_stages", 1)

	if disciple.cultivation_progress < 1.0:
		return {"success": false, "reason": "修为不足"}

	# 小阶段突破
	if disciple.sub_realm < sub_stages:
		return _attempt_sub_breakthrough(disciple)

	# 大境界突破
	else:
		return _attempt_realm_breakthrough(disciple)


func _attempt_sub_breakthrough(disciple: DiscipleData) -> Dictionary:
	var base_chance = 0.7 - (disciple.sub_realm * 0.05)
	var root_mult = DataRegistry.spirit_roots.get(disciple.spirit_root_quality, {}).get("breakthrough_mult", 1.0)
	var chance = clampf(base_chance * root_mult, 0.05, 0.95)

	if randf() < chance:
		disciple.sub_realm += 1
		disciple.cultivation_progress = 0.0
		disciple.breakthrough_attempts = 0
		return {"success": true, "type": "sub", "new_sub_realm": disciple.sub_realm}

	disciple.cultivation_progress -= 0.3
	disciple.breakthrough_attempts += 1
	return {"success": false, "reason": "突破失败", "progress_lost": 0.3}


func _attempt_realm_breakthrough(disciple: DiscipleData) -> Dictionary:
	var new_realm = disciple.realm + 1
	var realm_data = DataRegistry.cultivation_realms.get(new_realm, {})
	if realm_data.is_empty():
		return {"success": false, "reason": "已是最高境界"}

	var base_chance = _get_realm_base_chance(new_realm)
	var root_mult = DataRegistry.spirit_roots.get(disciple.spirit_root_quality, {}).get("breakthrough_mult", 1.0)
	var pill_aid = _consume_breakthrough_aid(disciple, new_realm)
	var pill_bonus = pill_aid.get("bonus", 0.0)
	var penalty = disciple.breakthrough_attempts * 0.03

	var chance = clampf((base_chance * root_mult) + pill_bonus - penalty, 0.01, 0.95)

	if randf() < chance:
		disciple.realm = new_realm
		disciple.sub_realm = 1
		disciple.cultivation_progress = 0.0
		disciple.breakthrough_attempts = 0
		disciple.lifespan = realm_data.get("lifespan", disciple.lifespan)
		var realm_name = DataRegistry.get_realm_name(new_realm)
		var memory = "宗门历%d年 突破至%s。" % [TimeManager.year, realm_name]
		if pill_aid.has("name"):
			memory += "突破前服用了%s。" % pill_aid["name"]
		disciple.add_memory(memory)

		EventBus.disciple_broken_through.emit(disciple.disciple_id, new_realm, 1)
		return {"success": true, "type": "realm", "new_realm": new_realm, "new_lifespan": disciple.lifespan}

	disciple.cultivation_progress -= 0.5
	disciple.breakthrough_attempts += 1
	if pill_aid.has("name"):
		disciple.add_memory("宗门历%d年 借%s冲击%s失败，修为受损。" % [
			TimeManager.year,
			pill_aid["name"],
			DataRegistry.get_realm_name(new_realm),
		])
	return {"success": false, "reason": "突破大境界失败", "progress_lost": 0.5}


func _get_realm_base_chance(realm: int) -> float:
	var chances = {2: 0.25, 3: 0.15, 4: 0.08, 5: 0.04, 6: 0.02, 7: 0.01, 8: 0.005}
	return chances.get(realm, 0.10)


func _consume_breakthrough_aid(_disciple: DiscipleData, target_realm: int) -> Dictionary:
	var sect = GameManager.current_sect
	if not sect:
		return {}

	var pill_map = {
		2: {"id": "foundation", "name": "筑基丹", "bonus": 0.20},
		3: {"id": "golden_core", "name": "结金丹", "bonus": 0.15},
	}
	var aid = pill_map.get(target_realm, {})
	if aid.is_empty():
		return {}
	if not sect.remove_inventory_item(aid["id"], 1):
		return {}
	return aid


func _check_aging(disciple: DiscipleData) -> void:
	var realm_data = DataRegistry.cultivation_realms.get(disciple.realm, {})
	var lifespan = realm_data.get("lifespan", 120)
	var aging_start = lifespan * 0.7

	if disciple.age > aging_start:
		var penalty = (disciple.age - aging_start) / (lifespan - aging_start)
		if penalty > 0.5:
			disciple.bone_structure = maxi(10, disciple.bone_structure - 1)
			disciple.talent = maxi(10, disciple.talent - 1)

	if disciple.age >= disciple.lifespan:
		disciple.alive = false
		disciple.add_memory("宗门历%d年 寿尽坐化。" % TimeManager.year)
		EventBus.disciple_died.emit(disciple.disciple_id, "寿尽坐化")
