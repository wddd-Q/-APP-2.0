extends Node
## 事件控制器 — 随机事件触发、选项处理、事件链管理


@export var event_pool: Array[Dictionary] = []
var active_events: Array[Dictionary] = []
var event_history: Array[String] = []
var event_cooldowns: Dictionary = {}  # {event_id: 剩余冷却月数}
var event_chain_state: Dictionary = {}


func _ready() -> void:
	_initialize_event_pool()


func roll_events() -> Array[Dictionary]:
	"""每月结算时调用，随机触发0-3个事件"""
	_process_cooldowns()

	var triggered: Array[Dictionary] = []
	var available = _get_available_events()

	if available.is_empty():
		return triggered

	var count = randi() % 4  # 0, 1, 2, 3
	for i in range(count):
		if available.is_empty():
			break
		var idx = randi() % available.size()
		var event = available.pop_at(idx)
		triggered.append(event)

		event_cooldowns[event["id"]] = event.get("cooldown", 3)
		event_history.append(event["id"])

		EventBus.random_event_triggered.emit(event["id"])

	active_events = triggered
	return triggered


func resolve_choice(event_id: String, choice: int) -> Dictionary:
	"""玩家做出选择后的结算"""
	for event in active_events:
		if event["id"] != event_id:
			continue

		var choices = event.get("choices", [])
		if choice >= choices.size():
			return {"error": "无效选择"}

		var selected = choices[choice]
		var result = _apply_event_effects(selected.get("effects", {}))

		if selected.has("chain_tag"):
			var tag = selected["chain_tag"]
			event_chain_state[tag] = TimeManager.year

		EventBus.event_choice_made.emit(event_id, choice)
		active_events.erase(event)
		return result

	return {"error": "事件不存在"}


func _initialize_event_pool() -> void:
	event_pool = [
		{
			"id": "wandering_cultivator",
			"name": "散修来投",
			"description": "一位云游四方的散修来到山门前，表示愿意加入宗门，但要求50灵石作为安家费用。",
			"scope": "sect",
			"rarity": "common",
			"cooldown": 6,
			"conditions": {"min_disciples": 0},
			"choices": [
				{"label": "收留", "effects": {"action": "recruit_wanderer", "spirit_stones": -50}},
				{"label": "拒绝", "effects": {"action": "nothing"}},
				{"label": "考验其能力后再决定", "effects": {"action": "test_wanderer", "spirit_stones": -100}},
			],
		},
		{
			"id": "beast_attack",
			"name": "妖兽袭击",
			"description": "一只妖兽从深山中窜出，袭击了宗门附近的灵田！若不阻止，灵草将损失惨重。",
			"scope": "sect",
			"rarity": "uncommon",
			"cooldown": 12,
			"conditions": {"min_disciples": 3},
			"choices": [
				{"label": "集结弟子迎战", "effects": {"action": "combat_beast"}},
				{"label": "避让，保存实力", "effects": {"action": "evacuate", "prestige": -20}},
			],
		},
		{
			"id": "merchant_caravan",
			"name": "商队路过",
			"description": "一支修仙界商队途经宗门附近，他们携带了各种珍稀物资，愿意与宗门交易。",
			"scope": "sect",
			"rarity": "common",
			"cooldown": 6,
			"conditions": {},
			"choices": [
				{"label": "高价收购材料", "effects": {"action": "open_trade", "spirit_stones": -200}},
				{"label": "保护商队换取声望", "effects": {"action": "guard_caravan", "prestige": 30}},
			],
		},
		{
			"id": "spirit_vein_anomaly",
			"name": "灵脉异动",
			"description": "宗门地下的灵脉突然传来剧烈的灵力波动，似乎有异宝即将出世！长老们建议投入500灵石进行探索。",
			"scope": "sect",
			"rarity": "rare",
			"cooldown": 24,
			"conditions": {"has_vein": true},
			"choices": [
				{"label": "投入资源全力探索", "effects": {"action": "invest_vein", "spirit_stones": -500}},
				{"label": "静观其变", "effects": {"action": "nothing"}},
			],
		},
		{
			"id": "disciple_enlightenment",
			"name": "弟子感悟",
			"description": "一位弟子在修炼中突有感悟，似乎触摸到了突破的契机。但他心境不稳，此时强行闭关有一定风险。",
			"scope": "disciple",
			"rarity": "uncommon",
			"cooldown": 12,
			"conditions": {"min_realm": 2},
			"choices": [
				{"label": "支持闭关突破", "effects": {"action": "force_cultivation", "risk": "heart_demon"}},
				{"label": "建议稳固根基后再突破", "effects": {"action": "safe_cultivation"}},
			],
		},
		{
			"id": "disciple_conflict",
			"name": "弟子争执",
			"description": "两位弟子因修炼资源分配不均发生口角，险些大打出手。其他弟子议论纷纷，需要掌门出面处理。",
			"scope": "disciple",
			"rarity": "common",
			"cooldown": 4,
			"conditions": {"min_disciples": 5},
			"choices": [
				{"label": "调解矛盾", "effects": {"action": "mediate", "spirit_stones": -20}},
				{"label": "放任自流", "effects": {"action": "ignore", "loyalty": -5}},
				{"label": "严惩不贷", "effects": {"action": "punish", "loyalty": -10, "sect_order": 5}},
			],
		},
	]


func _get_available_events() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var sect = GameManager.current_sect

	for event in event_pool:
		if event_cooldowns.get(event["id"], 0) > 0:
			continue
		if not _check_conditions(event.get("conditions", {}), sect):
			continue
		available.append(event.duplicate())

	return available


func _check_conditions(conditions: Dictionary, sect: Resource) -> bool:
	if conditions.has("min_disciples") and sect.disciples.size() < conditions["min_disciples"]:
		return false
	if conditions.has("min_realm"):
		var has_realm = false
		for d in sect.disciples:
			if d.realm >= conditions["min_realm"]:
				has_realm = true
				break
		if not has_realm:
			return false
	if conditions.has("has_vein"):
		if not sect.get_facility("spirit_vein"):
			return false
	return true


func _process_cooldowns() -> void:
	for event_id in event_cooldowns:
		event_cooldowns[event_id] -= 1
	var expired: Array[String] = []
	for event_id in event_cooldowns:
		if event_cooldowns[event_id] <= 0:
			expired.append(event_id)
	for event_id in expired:
		event_cooldowns.erase(event_id)


func _apply_event_effects(effects: Dictionary) -> Dictionary:
	var sect = GameManager.current_sect
	var result = {"effects_applied": effects.duplicate(), "messages": []}

	# 灵石变化
	if effects.has("spirit_stones"):
		var amount = effects["spirit_stones"]
		if amount < 0:
			if not sect.spend_spirit_stones(-amount):
				result["messages"].append("灵石不足！")
			else:
				result["messages"].append("消耗 %d 灵石" % -amount)
		else:
			sect.add_spirit_stones(amount)
			result["messages"].append("获得 %d 灵石" % amount)
		EventBus.spirit_stones_changed.emit(sect.spirit_stones, amount)

	# 声望变化
	if effects.has("prestige"):
		var delta = effects["prestige"]
		sect.prestige += delta
		result["messages"].append("声望 %+d" % delta)

	# 宗门秩序变化
	if effects.has("sect_order"):
		var delta = effects["sect_order"]
		sect.karma += delta
		result["messages"].append("宗门秩序 %+d" % delta)

	# 弟子忠诚度变化
	if effects.has("loyalty"):
		var delta = effects["loyalty"]
		_apply_loyalty_change(delta)
		result["messages"].append("弟子忠诚 %+d" % delta)

	# 具体action处理
	var action = effects.get("action", "")
	match action:
		"recruit_wanderer":
			_action_recruit_wanderer(result)
		"test_wanderer":
			_action_test_wanderer(result)
		"combat_beast":
			_action_combat_beast(result)
		"evacuate":
			_action_evacuate(result)
		"open_trade":
			_action_open_trade(result)
		"guard_caravan":
			_action_guard_caravan(result)
		"invest_vein":
			_action_invest_vein(result)
		"force_cultivation":
			_action_force_cultivation(result)
		"safe_cultivation":
			_action_safe_cultivation(result)
		"mediate":
			_action_mediate(result)
		"ignore":
			pass  # 不做任何事
		"punish":
			_action_punish(result)
		"nothing":
			pass

	return result


func _action_recruit_wanderer(result: Dictionary) -> void:
	var names_pool = ["风清扬", "林秋水", "苏长空", "白芷", "莫问天", "柳如烟", "叶无道", "花弄影"]
	var candidate = {
		"name": names_pool[randi() % names_pool.size()],
		"age": 16 + randi() % 20,
		"gender": randi() % 2,
		"bone_structure": 30 + randi() % 40,
		"comprehension": 30 + randi() % 40,
		"fortune": 30 + randi() % 40,
		"mentality": 30 + randi() % 40,
		"charm": 30 + randi() % 40,
		"talent": 30 + randi() % 40,
		"root_quality": _random_root_quality(),
		"elements": _random_elements(),
		"recruit_cost": 0,  # 事件已扣灵石，不再重复扣
	}
	var d = RecruitmentController.recruit(candidate)
	if d:
		result["messages"].append("%s 加入了宗门！" % d.disciple_name)
	else:
		result["messages"].append("招收失败")


func _action_test_wanderer(result: Dictionary) -> void:
	var names_pool = ["楚云飞", "慕容霜", "秦无极", "南宫流云", "东方灵秀"]
	var candidate = {
		"name": names_pool[randi() % names_pool.size()],
		"age": 18 + randi() % 15,
		"gender": randi() % 2,
		"bone_structure": 50 + randi() % 30,
		"comprehension": 50 + randi() % 30,
		"fortune": 50 + randi() % 30,
		"mentality": 50 + randi() % 30,
		"charm": 50 + randi() % 30,
		"talent": 50 + randi() % 30,
		"root_quality": _random_root_quality(),
		"elements": _random_elements(),
		"recruit_cost": 0,  # 事件已扣灵石，不再重复扣
	}
	var d = RecruitmentController.recruit(candidate)
	if d:
		result["messages"].append("经过考验，%s 资质出众，加入了宗门！" % d.disciple_name)
	else:
		result["messages"].append("招收失败")


func _action_combat_beast(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	var arena = sect.get_facility("arena")
	var arena_mult = 1.0
	if arena:
		arena_mult = 1.0 + DataRegistry.facility_templates.get("arena", {}).get("combat_bonus", {}).get(arena.level, 0.0)
	var combat_power = 0.0
	for d in sect.disciples:
		if d.alive:
			combat_power += (d.realm * 10 + d.sub_realm * 2) * arena_mult

	var beast_power = 20 + randi() % 40
	if combat_power > beast_power:
		var reward = 30 + randi() % 70
		sect.add_spirit_stones(reward)
		result["messages"].append("击败妖兽！获得 %d 灵石" % reward)
		EventBus.spirit_stones_changed.emit(sect.spirit_stones, reward)
	else:
		var loss = 5 + randi() % 15
		sect.remove_resource(sect.herbs, "spirit_herb", loss)
		result["messages"].append("战斗失利，损失了 %d 灵草" % loss)


func _action_evacuate(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	var loss = 3 + randi() % 10
	sect.remove_resource(sect.herbs, "spirit_herb", loss)
	result["messages"].append("避让妖兽，损失了 %d 灵草" % loss)


func _action_open_trade(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	var role = randi() % 4
	match role:
		0:
			var qty = 5 + randi() % 10
			sect.add_resource(sect.herbs, "spirit_herb", qty)
			result["messages"].append("购入 %d 灵草" % qty)
		1:
			var qty = 3 + randi() % 8
			sect.add_resource(sect.ores, "iron", qty)
			result["messages"].append("购入 %d 铁矿石" % qty)
		2:
			var qty = 1 + randi() % 3
			sect.add_resource(sect.herbs, "ginseng", qty)
			result["messages"].append("购入 %d 人参" % qty)
		3:
			var qty = 2 + randi() % 6
			sect.add_resource(sect.ores, "silk", qty)
			result["messages"].append("购入 %d 灵蚕丝" % qty)


func _action_guard_caravan(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	sect.prestige += 20
	result["messages"].append("保护商队获得了额外声望！")
	# 小概率遭遇强盗
	if randf() < 0.3:
		var bonus = 50 + randi() % 100
		sect.add_spirit_stones(bonus)
		result["messages"].append("击退拦路强盗，商队酬谢 %d 灵石" % bonus)
		EventBus.spirit_stones_changed.emit(sect.spirit_stones, bonus)


func _action_invest_vein(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	var vein = sect.get_facility("spirit_vein")
	if vein and randf() < 0.5:
		# 灵脉升级
		SectController.upgrade_facility("spirit_vein")
		result["messages"].append("灵脉异动引发灵气喷涌，灵脉升级！")
	elif randf() < 0.6:
		# 发现稀有材料
		var rare = "jade"
		var qty = 1 + randi() % 3
		sect.add_resource(sect.ores, rare, qty)
		sect.add_resource(sect.herbs, "lingzhi", qty)
		result["messages"].append("在灵脉深处发现了 %d 灵玉和 %d 灵芝！" % [qty, qty])
	else:
		var refund = 300
		sect.add_spirit_stones(refund)
		result["messages"].append("探索一无所获，回收了 %d 灵石" % refund)
		EventBus.spirit_stones_changed.emit(sect.spirit_stones, refund)


func _action_force_cultivation(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	var candidates: Array = []
	for d in sect.disciples:
		if d.alive and d.cultivation_progress >= 0.7:
			candidates.append(d)

	if candidates.is_empty():
		result["messages"].append("没有符合条件的弟子")
		return

	var target = candidates[randi() % candidates.size()]
	if randf() < 0.5:
		var bt = DiscipleController.check_breakthrough(target)
		if bt.get("success"):
			result["messages"].append("%s 成功突破到 %s！" % [target.disciple_name, DataRegistry.get_realm_name(target.realm)])
		else:
			result["messages"].append("%s 突破失败，心境受损" % target.disciple_name)
	else:
		target.cultivation_progress += 0.3
		result["messages"].append("%s 感悟颇深，修为大进" % target.disciple_name)


func _action_safe_cultivation(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	for d in sect.disciples:
		if d.alive and d.assigned_task == "cultivating":
			d.cultivation_progress += 0.15
	result["messages"].append("弟子们稳固根基，修为略有精进")


func _action_mediate(result: Dictionary) -> void:
	result["messages"].append("弟子之间的矛盾得以化解，宗门更加和睦")


func _action_punish(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	sect.karma += 5
	result["messages"].append("严惩违纪弟子，宗门秩序有所提升")


func _apply_loyalty_change(delta: int) -> void:
	# 忠诚度变化暂时不影响具体机制，未来可扩展
	pass


func _random_root_quality() -> String:
	var roll = randf()
	if roll < 0.005: return "heaven"
	if roll < 0.055: return "variant"
	if roll < 0.255: return "true"
	if roll < 0.705: return "false"
	return "waste"


func _random_elements() -> Array:
	var all = ["金", "木", "水", "火", "土"]
	var count = 1 + randi() % 5
	var result: Array = []
	for i in range(count):
		result.append(all[randi() % all.size()])
	return result
