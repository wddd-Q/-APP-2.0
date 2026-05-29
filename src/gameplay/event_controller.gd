extends Node
## 事件控制器 — 随机事件触发、选项处理、事件链管理


@export var event_pool: Array[Dictionary] = []
var active_events: Array[Dictionary] = []
var event_history: Array[String] = []
var event_cooldowns: Dictionary = {}  # {event_id: 剩余冷却月数}
var event_chain_state: Dictionary = {}
var event_records: Array[Dictionary] = []
var active_impacts: Array[Dictionary] = []
var months_since_event: int = 0
var unread_event_count: int = 0

const MONTHLY_EVENT_CHANCE := 0.35
const PITY_EVENT_MONTHS := 4
const MAX_EVENT_RECORDS := 80


func _ready() -> void:
	EventBus.game_started.connect(reset_state)
	_initialize_event_pool()


func reset_state() -> void:
	active_events.clear()
	event_history.clear()
	event_cooldowns.clear()
	event_chain_state.clear()
	event_records.clear()
	active_impacts.clear()
	months_since_event = 0
	unread_event_count = 0
	EventBus.event_ledger_changed.emit()


func roll_events() -> Array[Dictionary]:
	"""每月结算时调用，随机触发0-1个经营事件"""
	_process_cooldowns()
	_process_active_impacts()

	var triggered: Array[Dictionary] = []
	if not active_events.is_empty():
		return triggered

	var available = _get_available_events()

	if available.is_empty():
		months_since_event += 1
		return triggered

	var should_trigger = randf() < MONTHLY_EVENT_CHANCE or months_since_event >= PITY_EVENT_MONTHS
	if not should_trigger:
		months_since_event += 1
		return triggered

	var idx = randi() % available.size()
	var picked_event = available[idx]
	triggered.append(picked_event)

	event_cooldowns[picked_event["id"]] = picked_event.get("cooldown", 3)
	event_history.append(picked_event["id"])
	months_since_event = 0

	active_events = triggered
	for triggered_event in triggered:
		unread_event_count += 1
		EventBus.random_event_triggered.emit(triggered_event["id"])
	EventBus.event_ledger_changed.emit()
	return triggered


func resolve_choice(event_id: String, choice: int, handler_id: String = "") -> Dictionary:
	"""玩家做出选择后的结算"""
	for event in active_events:
		if event["id"] != event_id:
			continue

		var choices = event.get("choices", [])
		if choice >= choices.size():
			return {"error": "无效选择"}

		var selected = choices[choice]
		var result = _apply_event_effects(selected.get("effects", {}))
		result["handler"] = _get_handler_summary(handler_id)
		result["handler_judgement"] = get_choice_judgement(event_id, choice, handler_id)

		if selected.has("chain_tag"):
			var tag = selected["chain_tag"]
			event_chain_state[tag] = TimeManager.year

		if not result.get("blocked", false):
			_record_resolved_event(event, selected, result)
			_add_handler_memory(handler_id, event)

		EventBus.event_choice_made.emit(event_id, choice)
		if not result.get("blocked", false):
			active_events.erase(event)
		return result

	return {"error": "事件不存在"}


func mark_events_read() -> void:
	if unread_event_count == 0:
		return
	unread_event_count = 0
	EventBus.event_ledger_changed.emit()


func get_event_handlers() -> Array[Dictionary]:
	var handlers: Array[Dictionary] = [{
		"id": "",
		"name": "掌门亲自处理",
		"position": "掌门",
		"hint": "当前默认处理方式",
	}]
	var sect = GameManager.current_sect
	if not sect:
		return handlers

	for disciple in sect.disciples:
		if not disciple.alive:
			continue
		if disciple.position in ["副掌门", "副长老", "长老", "执事"]:
			handlers.append({
				"id": disciple.disciple_id,
				"name": disciple.disciple_name,
				"position": disciple.position,
				"hint": "%s · %s" % [disciple.position, DataRegistry.get_realm_name(disciple.realm)],
			})
	return handlers


func get_choice_judgement(event_id: String, choice_idx: int, handler_id: String = "") -> Dictionary:
	if handler_id == "":
		return {
			"score": 0,
			"label": "掌门定夺",
			"reason": "由掌门亲自处理，不受弟子性格影响。",
		}
	for event in active_events:
		if event.get("id", "") == event_id:
			return _judge_choice_by_handler(event, choice_idx, handler_id)
	return {"score": 0, "label": "无判断", "reason": "未找到待处理事件。"}


func _judge_choice_by_handler(event: Dictionary, choice_idx: int, handler_id: String) -> Dictionary:
	var disciple = _get_handler_disciple(handler_id)
	if not disciple:
		return {"score": 0, "label": "无判断", "reason": "未找到受命弟子。"}

	var choices = event.get("choices", [])
	if choice_idx < 0 or choice_idx >= choices.size():
		return {"score": 0, "label": "无判断", "reason": "无效选项。"}

	var choice = choices[choice_idx]
	var action = choice.get("effects", {}).get("action", "")
	var score = 0
	var reasons: Array[String] = []
	for personality in disciple.personalities:
		var delta = _get_personality_choice_affinity(personality, action, choice)
		score += delta
		if delta > 0:
			reasons.append("%s赞成此类处理" % personality)
		elif delta < 0:
			reasons.append("%s不喜此类处理" % personality)

	if disciple.position in ["副掌门", "副长老", "长老"] and abs(score) > 0:
		score += 1 if score > 0 else -1

	return {
		"score": score,
		"label": _get_judgement_label(score),
		"reason": _make_judgement_reason(disciple, reasons),
	}


func _get_personality_choice_affinity(personality: String, action: String, choice: Dictionary) -> int:
	var spend = int(choice.get("effects", {}).get("spirit_stones", 0)) < 0
	match personality:
		"勇猛":
			if action in ["combat_beast", "force_cultivation", "guard_caravan", "punish"]:
				return 2
			if action in ["evacuate", "safe_cultivation", "nothing"]:
				return -1
		"谨慎":
			if action in ["evacuate", "safe_cultivation", "temper_foundation", "mediate", "nothing"]:
				return 2
			if action in ["force_cultivation", "invest_vein", "combat_beast"]:
				return -2
		"贪婪":
			if action in ["open_trade", "invest_vein", "test_wanderer", "buy_foundation_materials"]:
				return 1
			if spend and action in ["reward_generation_oath", "steady_breakthrough", "mediate"]:
				return -1
		"忠诚":
			if action in ["record_generation_oath", "reward_generation_oath", "guard_caravan", "steady_breakthrough", "mediate"]:
				return 2
			if action in ["ignore", "nothing"]:
				return -1
		"孤傲":
			if action in ["punish", "self_decision", "test_wanderer", "force_cultivation"]:
				return 1
			if action in ["mediate", "recruit_wanderer"]:
				return -1
		"好奇":
			if action in ["invest_vein", "test_wanderer", "open_trade", "buy_foundation_materials", "alchemy_lecture"]:
				return 2
			if action in ["nothing", "evacuate"]:
				return -1
		"善良":
			if action in ["recruit_wanderer", "mediate", "guard_caravan", "steady_breakthrough", "reward_generation_oath"]:
				return 2
			if action in ["punish", "ignore", "evacuate"]:
				return -1
		"阴狠":
			if action in ["punish", "test_wanderer", "force_cultivation", "self_decision"]:
				return 2
			if action in ["mediate", "reward_generation_oath"]:
				return -1
	return 0


func _get_judgement_label(score: int) -> String:
	if score >= 4:
		return "强烈赞同"
	if score >= 2:
		return "倾向支持"
	if score <= -4:
		return "强烈反对"
	if score <= -2:
		return "不太赞成"
	return "可接受"


func _make_judgement_reason(disciple: Resource, reasons: Array[String]) -> String:
	var base = "%s（%s）" % [disciple.disciple_name, "、".join(disciple.personalities)]
	if reasons.is_empty():
		return "%s认为此事可由掌门权衡。" % base
	return "%s判断：%s。" % [base, "；".join(reasons.slice(0, 2))]


func _get_handler_summary(handler_id: String) -> Dictionary:
	if handler_id == "":
		return {"id": "", "name": "掌门", "position": "掌门"}
	var disciple = _get_handler_disciple(handler_id)
	if not disciple:
		return {"id": handler_id, "name": "未知弟子", "position": "未知"}
	return {
		"id": disciple.disciple_id,
		"name": disciple.disciple_name,
		"position": disciple.position,
		"personalities": disciple.personalities.duplicate(),
	}


func _add_handler_memory(handler_id: String, event: Dictionary) -> void:
	var disciple = _get_handler_disciple(handler_id)
	if not disciple:
		return
	disciple.add_memory("宗门历%d年 受命处理宗门纪事「%s」。" % [TimeManager.year, event.get("name", "事件")])


func _get_handler_disciple(handler_id: String):
	var sect = GameManager.current_sect
	if not sect or handler_id == "":
		return null
	if sect.has_method("get_disciple_by_id"):
		return sect.get_disciple_by_id(handler_id)
	for disciple in sect.disciples:
		if disciple.disciple_id == handler_id:
			return disciple
	return null


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
		{
			"id": "foundation_pill_commission",
			"name": "老丹师借炉",
			"description": "一位白发丹师路过山门，听闻本门有弟子将近筑基，愿借宗门丹炉代炼一枚筑基丹，但需支付180灵石作为炉火与药引费用。",
			"scope": "sect",
			"rarity": "uncommon",
			"cooldown": 18,
			"conditions": {"max_year": 5, "missing_item": "foundation"},
			"choices": [
				{"label": "请其代炼筑基丹", "effects": {"action": "commission_foundation_pill", "spirit_stones": -180}},
				{"label": "只请教炼丹心得", "effects": {"action": "alchemy_lecture", "spirit_stones": -60}},
				{"label": "婉拒", "effects": {"action": "nothing"}},
			],
		},
		{
			"id": "senior_breakthrough_anxiety",
			"name": "闭关前夜",
			"description": "即将触及瓶颈的弟子整夜未眠，担心自己一旦突破失败，会拖累宗门前程。掌门需要给出态度。",
			"scope": "disciple",
			"rarity": "common",
			"cooldown": 8,
			"conditions": {"min_progress": 0.65},
			"choices": [
				{"label": "亲自护法，稳其心神", "effects": {"action": "steady_breakthrough", "spirit_stones": -40}},
				{"label": "令其继续打磨根基", "effects": {"action": "temper_foundation"}},
				{"label": "让他自行决断", "effects": {"action": "self_decision"}},
			],
		},
		{
			"id": "market_foundation_materials",
			"name": "坊市药材风声",
			"description": "坊市传来消息，有散修急售数味筑基辅药。价格不算便宜，但错过之后短期内未必还能遇到。",
			"scope": "sect",
			"rarity": "common",
			"cooldown": 10,
			"conditions": {"max_year": 5},
			"choices": [
				{"label": "买下辅药", "effects": {"action": "buy_foundation_materials", "spirit_stones": -120}},
				{"label": "只买普通灵草", "effects": {"action": "buy_basic_herbs", "spirit_stones": -50}},
				{"label": "暂不采购", "effects": {"action": "nothing"}},
			],
		},
		{
			"id": "first_generation_oath",
			"name": "初代弟子立誓",
			"description": "夜色下，几名初代弟子在山门前自发立誓：愿与宗门同进退。此事虽小，却能凝聚人心。",
			"scope": "disciple",
			"rarity": "uncommon",
			"cooldown": 24,
			"conditions": {"min_disciples": 3, "max_year": 3},
			"choices": [
				{"label": "记入宗门名册", "effects": {"action": "record_generation_oath", "prestige": 20}},
				{"label": "赐下灵石嘉奖", "effects": {"action": "reward_generation_oath", "spirit_stones": -90}},
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
	if conditions.has("max_year") and TimeManager.year > conditions["max_year"]:
		return false
	if conditions.has("missing_item") and _has_inventory_item(sect, conditions["missing_item"]):
		return false
	if conditions.has("min_progress"):
		var has_progress = false
		for d in sect.disciples:
			if d.alive and d.cultivation_progress >= conditions["min_progress"]:
				has_progress = true
				break
		if not has_progress:
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


func _process_active_impacts() -> void:
	if active_impacts.is_empty():
		return

	var changed = false
	var expired: Array[Dictionary] = []
	for impact in active_impacts:
		impact["months_remaining"] = int(impact.get("months_remaining", 0)) - 1
		if impact["months_remaining"] <= 0:
			expired.append(impact)
		changed = true

	for impact in expired:
		active_impacts.erase(impact)

	if changed:
		EventBus.event_ledger_changed.emit()


func _record_resolved_event(event: Dictionary, selected: Dictionary, result: Dictionary) -> void:
	var impact = _make_impact_summary(event, selected, result)
	var record = {
		"record_id": "%s_%d_%d_%d" % [event.get("id", "event"), TimeManager.year, TimeManager.month, event_records.size()],
		"event_id": event.get("id", ""),
		"title": event.get("name", "事件"),
		"scope": _get_scope_label(event.get("scope", "sect")),
		"rarity": _get_rarity_label(event.get("rarity", "common")),
		"date": TimeManager.get_date_string(),
		"choice": selected.get("label", "未记录"),
		"messages": result.get("messages", []).duplicate(),
		"immediate": _summarize_effects(result.get("effects_applied", {}), result.get("messages", [])),
		"long_term": impact.get("summary", "无持续影响"),
		"months_remaining": impact.get("months", 0),
		"category": event.get("category", "经营事件"),
		"is_story": event.get("is_story", false),
		"handler": result.get("handler", {}),
		"handler_judgement": result.get("handler_judgement", {}),
	}
	event_records.push_front(record)
	if event_records.size() > MAX_EVENT_RECORDS:
		event_records.resize(MAX_EVENT_RECORDS)

	if int(impact.get("months", 0)) > 0:
		active_impacts.push_front({
			"record_id": record["record_id"],
			"title": record["title"],
			"date": record["date"],
			"summary": impact["summary"],
			"months_remaining": impact["months"],
			"severity": impact.get("severity", "neutral"),
		})

	EventBus.event_ledger_changed.emit()


func _make_impact_summary(event: Dictionary, selected: Dictionary, result: Dictionary) -> Dictionary:
	if selected.has("impact"):
		return {
			"summary": selected.get("impact", "无持续影响"),
			"months": selected.get("impact_months", 0),
			"severity": selected.get("impact_severity", "neutral"),
		}

	var effects = result.get("effects_applied", {})
	var action = effects.get("action", "")
	match action:
		"combat_beast":
			return {"summary": "山门周边妖兽被震慑，短期内灵田较安稳。", "months": 3, "severity": "good"}
		"evacuate":
			return {"summary": "弟子避战保全实力，但附近妖兽活动仍未平息。", "months": 2, "severity": "warning"}
		"guard_caravan":
			return {"summary": "商队愿意继续往来，坊市传闻对本门更友善。", "months": 4, "severity": "good"}
		"open_trade":
			return {"summary": "近期物资流通增加，仓库获得一次性补给。", "months": 1, "severity": "neutral"}
		"force_cultivation":
			return {"summary": "门内修炼气氛紧绷，突破收益与心魔风险并存。", "months": 2, "severity": "warning"}
		"safe_cultivation", "steady_breakthrough", "temper_foundation":
			return {"summary": "弟子心态趋稳，闭关与突破反馈已记入名册。", "months": 3, "severity": "good"}
		"mediate", "punish":
			return {"summary": "门内秩序得到处理，弟子会观察掌门后续赏罚。", "months": 2, "severity": "neutral"}
		"record_generation_oath", "reward_generation_oath":
			return {"summary": "初代弟子的归属感增强，此事成为宗门早期记忆。", "months": 6, "severity": "good"}
		_:
			return {"summary": "此事已归档，目前没有持续影响。", "months": 0, "severity": "neutral"}


func _summarize_effects(effects: Dictionary, messages: Array) -> String:
	if not messages.is_empty():
		return "；".join(messages)
	var parts: Array[String] = []
	if effects.has("spirit_stones"):
		parts.append("灵石 %+d" % effects["spirit_stones"])
	if effects.has("prestige"):
		parts.append("声望 %+d" % effects["prestige"])
	if effects.has("loyalty"):
		parts.append("弟子忠诚 %+d" % effects["loyalty"])
	if effects.has("sect_order"):
		parts.append("宗门秩序 %+d" % effects["sect_order"])
	if parts.is_empty():
		return "无直接数值变化"
	return "；".join(parts)


func _get_scope_label(scope: String) -> String:
	var labels = {
		"sect": "宗门",
		"disciple": "弟子",
		"region": "区域",
		"world": "天下",
	}
	return labels.get(scope, scope)


func _get_rarity_label(rarity: String) -> String:
	var labels = {
		"common": "常见",
		"uncommon": "不凡",
		"rare": "稀有",
		"epic": "史诗",
		"legendary": "传说",
	}
	return labels.get(rarity, rarity)


func _apply_event_effects(effects: Dictionary) -> Dictionary:
	var sect = GameManager.current_sect
	var result = {"effects_applied": effects.duplicate(), "messages": []}

	# 灵石变化
	if effects.has("spirit_stones"):
		var amount = effects["spirit_stones"]
		if amount < 0:
			if not sect.spend_spirit_stones(-amount):
				result["messages"].append("灵石不足！")
				result["blocked"] = true
				return result
			else:
				result["messages"].append("消耗 %d 灵石" % -amount)
				EventBus.spirit_stones_changed.emit(sect.spirit_stones, amount)
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
		"commission_foundation_pill":
			_action_commission_foundation_pill(result)
		"alchemy_lecture":
			_action_alchemy_lecture(result)
		"steady_breakthrough":
			_action_steady_breakthrough(result)
		"temper_foundation":
			_action_temper_foundation(result)
		"self_decision":
			_action_self_decision(result)
		"buy_foundation_materials":
			_action_buy_foundation_materials(result)
		"buy_basic_herbs":
			_action_buy_basic_herbs(result)
		"record_generation_oath":
			_action_record_generation_oath(result)
		"reward_generation_oath":
			_action_reward_generation_oath(result)
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


func _action_commission_foundation_pill(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	sect.add_inventory_item("foundation", "筑基丹", 0, 2, 1, {"breakthrough_realm": 2})
	result["messages"].append("老丹师代炼成功，宗门获得中品筑基丹。")


func _action_alchemy_lecture(result: Dictionary) -> void:
	var target = _get_best_skill_disciple("alchemy")
	if not target:
		result["messages"].append("无人适合听讲。")
		return
	target.skills["alchemy"] = mini(100, target.skills.get("alchemy", 0) + 8)
	target.add_memory("宗门历%d年 听老丹师讲火候药性，炼丹术有所精进。" % TimeManager.year)
	result["messages"].append("%s 炼丹术提升。" % target.disciple_name)


func _action_steady_breakthrough(result: Dictionary) -> void:
	var target = _get_most_advanced_disciple()
	if not target:
		return
	target.mentality = mini(100, target.mentality + 5)
	target.cultivation_progress = minf(1.15, target.cultivation_progress + 0.12)
	target.add_memory("宗门历%d年 闭关前夜得掌门护法，心神渐定。" % TimeManager.year)
	result["messages"].append("%s 心境稳固，修为更进一步。" % target.disciple_name)


func _action_temper_foundation(result: Dictionary) -> void:
	var target = _get_most_advanced_disciple()
	if not target:
		return
	target.bone_structure = mini(100, target.bone_structure + 3)
	target.mentality = mini(100, target.mentality + 3)
	target.add_memory("宗门历%d年 遵掌门令继续打磨根基，未急于破关。" % TimeManager.year)
	result["messages"].append("%s 根基更稳，但突破时机暂缓。" % target.disciple_name)


func _action_self_decision(result: Dictionary) -> void:
	var target = _get_most_advanced_disciple()
	if not target:
		return
	if randf() < 0.45:
		target.cultivation_progress = minf(1.1, target.cultivation_progress + 0.2)
		target.add_memory("宗门历%d年 自行参悟瓶颈，似有所获。" % TimeManager.year)
		result["messages"].append("%s 自行参悟，修为上涨。" % target.disciple_name)
	else:
		target.mentality = maxi(10, target.mentality - 4)
		target.add_memory("宗门历%d年 独自面对瓶颈，心绪一度不宁。" % TimeManager.year)
		result["messages"].append("%s 心境略有波动。" % target.disciple_name)


func _action_buy_foundation_materials(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	sect.add_resource(sect.herbs, "ginseng", 2)
	sect.add_resource(sect.herbs, "lingzhi", 1)
	result["messages"].append("购得人参2株、灵芝1株，可用于后续炼丹。")


func _action_buy_basic_herbs(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	sect.add_resource(sect.herbs, "spirit_herb", 10)
	result["messages"].append("购得10株灵草。")


func _action_record_generation_oath(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	for d in sect.disciples:
		if d.alive:
			d.add_memory("宗门历%d年 于山门前立下初代弟子之誓。" % TimeManager.year)
	result["messages"].append("初代弟子之誓记入宗门名册。")


func _action_reward_generation_oath(result: Dictionary) -> void:
	var sect = GameManager.current_sect
	for d in sect.disciples:
		if d.alive:
			d.cultivation_progress = minf(1.0, d.cultivation_progress + 0.08)
			d.add_memory("宗门历%d年 因初代弟子之誓受掌门嘉奖。" % TimeManager.year)
	result["messages"].append("弟子士气大振，修为略有增长。")


func _apply_loyalty_change(delta: int) -> void:
	# 忠诚度变化暂时不影响具体机制，未来可扩展
	pass


func _has_inventory_item(sect: Resource, item_id: String) -> bool:
	for item in sect.inventory:
		if item.item_id == item_id and item.quantity > 0:
			return true
	return false


func _get_most_advanced_disciple():
	var sect = GameManager.current_sect
	if not sect:
		return null
	var best = null
	var best_score = -1.0
	for d in sect.disciples:
		if not d.alive:
			continue
		var score = d.realm * 100.0 + d.sub_realm * 10.0 + d.cultivation_progress
		if score > best_score:
			best_score = score
			best = d
	return best


func _get_best_skill_disciple(skill_id: String):
	var sect = GameManager.current_sect
	if not sect:
		return null
	var best = null
	var best_value = -1
	for d in sect.disciples:
		if not d.alive:
			continue
		var value = d.skills.get(skill_id, 0) + int(d.comprehension / 10)
		if value > best_value:
			best_value = value
			best = d
	return best


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
