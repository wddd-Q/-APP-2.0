extends Node
## 副本控制器 — 管理副本实例、派遣、结算

const DungeonData = preload("res://src/core/data/dungeon_data.gd")

var dungeon_instances: Dictionary = {}
var active_expeditions: Array[Dictionary] = []
var _total_month: int = 0


func _ready() -> void:
	EventBus.month_passed.connect(_on_month_passed)
	EventBus.game_started.connect(_init_all_dungeons)


func _on_month_passed(month: int, year: int) -> void:
	_total_month = month


func _init_all_dungeons() -> void:
	dungeon_instances.clear()
	active_expeditions.clear()
	for dungeon_id in DataRegistry.dungeon_templates:
		var template = DataRegistry.dungeon_templates[dungeon_id]
		var d = DungeonData.new()
		d.dungeon_id = dungeon_id
		d.dungeon_name = template["dungeon_name"]
		d.dungeon_type = template["dungeon_type"]
		d.difficulty = template["difficulty"]
		d.danger_level = template["danger_level"]
		d.exploration_months = template["exploration_months"]
		d.min_disciple_realm = template["min_disciple_realm"]
		d.min_disciple_count = template["min_disciple_count"]
		d.max_disciple_count = template["max_disciple_count"]
		d.cooldown_duration = template["cooldown_duration"]
		d.description = template["description"]
		d.loot_pool = template["loot_pool"]
		d.event_pool = template["event_pool"]
		# 初始副本中，靠近玩家起始区域的自动被发现
		if dungeon_id in ["spirit_mine", "misty_valley"]:
			d.is_discovered = true
		dungeon_instances[dungeon_id] = d


func get_available_dungeons() -> Array:
	var result: Array = []
	for d in dungeon_instances.values():
		if d.is_available():
			result.append(d)
	return result


func discover_dungeon(dungeon_id: String) -> void:
	if not dungeon_instances.has(dungeon_id):
		return
	var d = dungeon_instances[dungeon_id]
	if d.is_discovered:
		return
	d.is_discovered = true
	EventBus.dungeon_discovered.emit(dungeon_id)


func dispatch_expedition(dungeon_id: String, disciple_ids: Array, allied_faction: String = "") -> Dictionary:
	if not dungeon_instances.has(dungeon_id):
		return {"success": false, "error": "副本不存在"}

	var d: DungeonData = dungeon_instances[dungeon_id]
	if not d.is_available():
		return {"success": false, "error": "副本不可用"}

	var sect = GameManager.current_sect
	if not sect:
		return {"success": false, "error": "无宗门数据"}

	if disciple_ids.size() < d.min_disciple_count:
		return {"success": false, "error": "弟子人数不足（需要%d人）" % d.min_disciple_count}
	if disciple_ids.size() > d.max_disciple_count:
		return {"success": false, "error": "弟子人数超过上限（最多%d人）" % d.max_disciple_count}

	# 派遣费
	var cost = d.difficulty * 20
	if not sect.spend_spirit_stones(cost):
		return {"success": false, "error": "灵石不足（需要%d）" % cost}
	EventBus.spirit_stones_changed.emit(sect.spirit_stones, -cost)

	# 找到弟子并设置状态
	var dispatched: Array = []
	for did in disciple_ids:
		for disciple in sect.disciples:
			if disciple.resource_path == did and disciple.alive:
				if disciple.assigned_task != "idle":
					return {"success": false, "error": "%s 正在执行其他任务" % disciple.disciple_name}
				if disciple.realm < d.min_disciple_realm:
					return {"success": false, "error": "%s 境界不足" % disciple.disciple_name}
				disciple.assigned_task = "exploring"
				disciple.set_meta("location", dungeon_id)
				dispatched.append(disciple)
				break

	if dispatched.size() < d.min_disciple_count:
		return {"success": false, "error": "符合条件的弟子不足"}

	# 消耗盟友关系
	if allied_faction != "":
		for faction in WorldController.npc_factions:
			if faction.faction_name == allied_faction:
				faction.relation_to_player = maxi(-100, faction.relation_to_player - 5)
				break

	# 记录探索
	var now = TimeManager.month + TimeManager.year * 12
	d.start_expedition(disciple_ids, allied_faction, now)

	var exp_record = {
		"dungeon_id": dungeon_id,
		"disciple_ids": disciple_ids,
		"allied_faction": allied_faction,
		"complete_month": now + d.exploration_months,
	}
	active_expeditions.append(exp_record)
	EventBus.dungeon_expedition_started.emit(dungeon_id, disciple_ids)
	return {"success": true, "message": "派遣成功！%d个月后返回" % d.exploration_months}


func process_monthly() -> void:
	var sect = GameManager.current_sect
	if not sect:
		return

	var now = TimeManager.month + TimeManager.year * 12
	var completed: Array[Dictionary] = []

	for exp in active_expeditions:
		if exp["complete_month"] <= now:
			completed.append(exp)

	for exp in completed:
		active_expeditions.erase(exp)
		_resolve_expedition(exp)


func _resolve_expedition(exp: Dictionary) -> void:
	var dungeon_id = exp["dungeon_id"]
	var d: DungeonData = dungeon_instances.get(dungeon_id)
	if not d:
		return

	# 恢复弟子状态
	var sect = GameManager.current_sect
	for did in exp["disciple_ids"]:
		for disciple in sect.disciples:
			if disciple.resource_path == did:
				disciple.assigned_task = "idle"
				disciple.remove_meta("location")
				break

	# 计算战力（含演武场加成）
	var arena = sect.get_facility("arena")
	var arena_mult = 1.0
	if arena:
		arena_mult = 1.0 + DataRegistry.facility_templates.get("arena", {}).get("combat_bonus", {}).get(arena.level, 0.0)
	var total_power = 0.0
	for did in exp["disciple_ids"]:
		for disciple in sect.disciples:
			if disciple.resource_path == did:
				total_power += (disciple.realm * 10 + disciple.sub_realm * 2) * arena_mult
				break

	# 盟友加成
	if exp["allied_faction"] != "":
		total_power = int(total_power * 1.2)

	# 成功率
	var success_chance = clampf(float(total_power) / (d.difficulty * 25.0), 0.1, 0.95)
	var success = randf() < success_chance

	var loot: Dictionary = {}
	if success:
		loot = _generate_loot(d.loot_pool)

	d.clear_expedition()

	var result_msg = ""
	if success:
		result_msg = "探索%s成功！" % d.dungeon_name
	else:
		result_msg = "探索%s失败，弟子们无功而返。" % d.dungeon_name
		# 失败惩罚：部分弟子受伤
		for did in exp["disciple_ids"]:
			if randf() < 0.3:
				for disciple in sect.disciples:
					if disciple.resource_path == did:
						disciple.cultivation_progress = maxf(0.0, disciple.cultivation_progress - 0.2)
						break

	EventBus.dungeon_expedition_finished.emit(dungeon_id, success, loot)


func _generate_loot(loot_pool: Array) -> Dictionary:
	var result: Dictionary = {}
	var sect = GameManager.current_sect

	for entry in loot_pool:
		if randf() * 100 > entry["weight"]:
			continue

		var qty = entry["base_quantity"] + randi() % maxi(1, entry["base_quantity"] / 2)
		var item_type = entry["item_type"]

		match item_type:
			"spirit_stones":
				sect.add_spirit_stones(qty)
				EventBus.spirit_stones_changed.emit(sect.spirit_stones, qty)
				result["spirit_stones"] = result.get("spirit_stones", 0) + qty
			"herb":
				var item_id = entry.get("item_id", "spirit_herb")
				sect.add_resource(sect.herbs, item_id, qty)
				var key = "herb_%s" % item_id
				result[key] = result.get(key, 0) + qty
			"ore":
				var item_id = entry.get("item_id", "iron")
				sect.add_resource(sect.ores, item_id, qty)
				var key = "ore_%s" % item_id
				result[key] = result.get(key, 0) + qty
			"rare_material":
				var item_id = entry.get("item_id", "unknown")
				sect.add_resource(sect.rare_materials, item_id, qty)
				var key = "rare_%s" % item_id
				result[key] = result.get(key, 0) + qty
			"equipment", "technique_scroll":
				var key = "%s_%s" % [item_type, entry.get("item_id", "unknown")]
				result[key] = result.get(key, 0) + qty
			"prestige":
				sect.prestige += qty
				result["prestige"] = result.get("prestige", 0) + qty

	return result


func get_active_expedition_text() -> String:
	var now = TimeManager.month + TimeManager.year * 12
	var texts: Array[String] = []

	for exp in active_expeditions:
		var d: DungeonData = dungeon_instances.get(exp["dungeon_id"])
		if not d:
			continue
		var remaining = maxi(0, exp["complete_month"] - now)

		var disciple_names: Array[String] = []
		var sect = GameManager.current_sect
		for did in exp["disciple_ids"]:
			for disc in sect.disciples:
				if disc.resource_path == did:
					disciple_names.append(disc.disciple_name)
					break

		texts.append("%s — %s（剩余%d月）%s" % [
			d.dungeon_name,
			", ".join(disciple_names),
			remaining,
			" [与%s同行]" % exp["allied_faction"] if exp["allied_faction"] != "" else "",
		])

	return "\n".join(texts) if not texts.is_empty() else "暂无进行中的探索"


func get_allied_factions() -> Array:
	var result: Array = []
	for faction in WorldController.npc_factions:
		if faction.is_alive and faction.relation_to_player >= 30:
			result.append(faction)
	return result
