class_name SectOverview
extends Control
## 宗门总览界面 — 核心主界面

const DisciplePortrait = preload("res://src/ui/disciple_portrait.gd")

@onready var sect_name_label: Label = $SectInfo/SectNameLabel
@onready var rank_label: Label = $SectInfo/RankLabel
@onready var facilities_container: Control = $Facilities/FacilitiesList
@onready var disciples_container: Control = $Disciples/DisciplesBrief
@onready var resources_container: Control = $Resources/ResourcesList
@onready var active_decrees_label: Label = $Decrees/ActiveDecreesLabel

var _recruit_panel: DiscipleRecruitPanel
var _detail_panel: DiscipleDetailPanel
var _recruit_btn: Button
var _build_selector: OptionButton


func _ready() -> void:
	EventBus.month_passed.connect(_refresh)
	EventBus.facility_built.connect(_on_facility_changed)
	EventBus.facility_upgraded.connect(_on_facility_changed)
	EventBus.sect_rank_changed.connect(_on_rank_changed)
	EventBus.disciple_recruited.connect(_on_disciples_changed)
	EventBus.disciple_died.connect(_on_disciples_changed)
	EventBus.game_started.connect(_on_game_started)

	var root = get_node("../../..")
	_recruit_panel = root.get_node("DiscipleRecruitPanel")
	_detail_panel = root.get_node("DiscipleDetailPanel")

	_recruit_btn = Button.new()
	_recruit_btn.text = "招收弟子 +"
	_recruit_btn.add_theme_font_size_override("font_size", 18)
	_recruit_btn.pressed.connect(_on_recruit_pressed)
	$Disciples.add_child(_recruit_btn)
	$Disciples.move_child(_recruit_btn, 1)

	if GameManager.current_sect:
		_refresh(TimeManager.month, TimeManager.year)


func _on_game_started() -> void:
	_refresh(TimeManager.month, TimeManager.year)


func _refresh(_month: int, _year: int) -> void:
	var sect = GameManager.current_sect
	if not sect:
		return

	sect_name_label.text = sect.name
	rank_label.text = _get_rank_display(sect.rank)
	_refresh_facilities(sect)
	_refresh_disciples_brief(sect)
	_refresh_resources(sect)
	_refresh_decrees(sect)


func _refresh_facilities(sect: Resource) -> void:
	for child in facilities_container.get_children():
		child.queue_free()

	for facility in sect.facilities:
		var template = DataRegistry.facility_templates.get(facility.facility_type, {})
		var max_lv = template.get("max_level", 3)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var label = Label.new()
		label.text = "%s Lv.%d (维护:%d灵石/月)" % [
			template.get("name", "未知"),
			facility.level,
			template.get("maintenance", {}).get(facility.level, 0),
		]
		label.add_theme_font_size_override("font_size", 16)
		row.add_child(label)

		if facility.level < max_lv:
			var next_cost = template.get("build_cost", {}).get(facility.level + 1, 0)
			var up_btn = Button.new()
			up_btn.text = "升级(%d灵石)" % next_cost
			up_btn.add_theme_font_size_override("font_size", 14)
			var ftype = facility.facility_type
			up_btn.pressed.connect(func(): _on_upgrade(ftype))
			row.add_child(up_btn)

		facilities_container.add_child(row)

	# 建造新设施
	var remaining = sect.max_facilities() - sect.facilities.size()
	if remaining > 0:
		var hint = Label.new()
		hint.text = "（还可建造 %d 座设施）" % remaining
		hint.modulate = Color.GRAY
		facilities_container.add_child(hint)

		var build_row = HBoxContainer.new()
		build_row.add_theme_constant_override("separation", 8)

		_build_selector = OptionButton.new()
		_build_selector.add_theme_font_size_override("font_size", 14)
		for type_key in DataRegistry.facility_templates:
			var tmpl = DataRegistry.facility_templates[type_key]
			# 排除已建造的设施
			if sect.get_facility(type_key):
				continue
			var cost = tmpl.get("build_cost", {}).get(1, 0)
			_build_selector.add_item("%s (%d灵石)" % [tmpl["name"], cost])
			_build_selector.set_item_metadata(_build_selector.item_count - 1, type_key)
		build_row.add_child(_build_selector)

		var build_btn = Button.new()
		build_btn.text = "建造"
		build_btn.add_theme_font_size_override("font_size", 14)
		build_btn.pressed.connect(_on_build)
		build_row.add_child(build_btn)

		facilities_container.add_child(build_row)
	else:
		var hint = Label.new()
		hint.text = "设施数量已达上限"
		hint.modulate = Color.GRAY
		facilities_container.add_child(hint)


func _on_upgrade(facility_type: String) -> void:
	var ok = SectController.upgrade_facility(facility_type)
	if not ok:
		print("升级失败: 灵石不足")


func _on_build() -> void:
	if _build_selector.selected < 0:
		return
	var type_key = _build_selector.get_item_metadata(_build_selector.selected)
	var ok = SectController.build_facility(type_key)
	if not ok:
		print("建造失败: 灵石不足或已达上限")


func _refresh_disciples_brief(sect: Resource) -> void:
	for child in disciples_container.get_children():
		child.queue_free()

	var sorted = sect.disciples.duplicate()
	sorted.sort_custom(func(a, b): return a.realm > b.realm or (a.realm == b.realm and a.sub_realm > b.sub_realm))

	for d in sorted.slice(0, 10):
		if not d.alive:
			continue

		# 行容器：头像 + 信息按钮
		var card = VBoxContainer.new()
		card.add_theme_constant_override("separation", 4)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var portrait = DisciplePortrait.new()
		portrait.setup(d, 40)
		row.add_child(portrait)

		var btn = Button.new()
		btn.text = "[%s] %s | %s%s层 | %s | %d岁 | %s" % [
			d.position,
			d.disciple_name,
			DataRegistry.get_realm_name(d.realm),
			d.sub_realm,
			DataRegistry.spirit_roots.get(d.spirit_root_quality, {}).get("name", "?灵根"),
			d.age,
			_get_task_display(d.assigned_task),
		]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 16)
		btn.flat = true
		var disciple = d
		btn.pressed.connect(func(): _detail_panel.show_disciple(disciple))
		row.add_child(btn)

		card.add_child(row)

		var progress = ProgressBar.new()
		progress.min_value = 0
		progress.max_value = 100
		progress.value = clampf(d.cultivation_progress * 100.0, 0.0, 100.0)
		progress.custom_minimum_size = Vector2(0, 10)
		progress.show_percentage = false
		card.add_child(progress)

		var next_hint = Label.new()
		next_hint.text = _get_disciple_focus_hint(d)
		next_hint.add_theme_font_size_override("font_size", 13)
		next_hint.add_theme_color_override("font_color", Color(0.72, 0.68, 0.55, 1.0))
		card.add_child(next_hint)

		disciples_container.add_child(card)


func _refresh_resources(sect: Resource) -> void:
	for child in resources_container.get_children():
		child.queue_free()

	var main = Label.new()
	main.text = "灵石: %d  |  预计月结: %+d" % [sect.spirit_stones, _get_monthly_stone_projection(sect)]
	main.add_theme_font_size_override("font_size", 18)
	if _get_monthly_stone_projection(sect) < 0:
		main.add_theme_color_override("font_color", Color(0.95, 0.38, 0.28, 1.0))
	resources_container.add_child(main)
	_add_world_rank_summary()

	if not sect.herbs.is_empty():
		var herbs_label = Label.new()
		herbs_label.text = "灵草: " + _format_resource_dict(sect.herbs)
		herbs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		resources_container.add_child(herbs_label)

	if not sect.ores.is_empty():
		var ores_label = Label.new()
		ores_label.text = "矿石: " + _format_resource_dict(sect.ores)
		ores_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		resources_container.add_child(ores_label)

	if not sect.inventory.is_empty():
		var pills = _count_inventory_by_type(sect, 0)
		if pills > 0:
			var pill_label = Label.new()
			pill_label.text = "丹药库存: %d" % pills
			resources_container.add_child(pill_label)


func _add_world_rank_summary() -> void:
	var summary = WorldController.get_player_ranking_summary()
	if summary.is_empty():
		return

	var entry = summary.get("entry", {})
	var above = summary.get("above", {})
	var rank_label = Label.new()
	if above.is_empty():
		rank_label.text = "天下排名: 第 %d / %d | 综合 %d | 暂居榜首" % [
			summary.get("rank", 0),
			summary.get("total", 0),
			entry.get("score", 0),
		]
	else:
		rank_label.text = "天下排名: 第 %d / %d | 综合 %d | 距上一名差 %d" % [
			summary.get("rank", 0),
			summary.get("total", 0),
			entry.get("score", 0),
			summary.get("score_gap", 0),
		]
	rank_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rank_label.add_theme_font_size_override("font_size", 16)
	rank_label.add_theme_color_override("font_color", Color(0.9, 0.78, 0.35, 1.0))
	resources_container.add_child(rank_label)


func _refresh_decrees(sect: Resource) -> void:
	var lines: Array[String] = []
	lines.append("当前门规: " + ("无" if sect.active_decrees.is_empty() else ", ".join(sect.active_decrees)))
	lines.append("")
	lines.append("近期宗门记事")
	var memories = _get_recent_memories(sect, 4)
	if memories.is_empty():
		lines.append("尚无重要记录")
	else:
		for memory in memories:
			lines.append("· " + memory)
	active_decrees_label.text = "\n".join(lines)
	active_decrees_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _on_facility_changed(_type: String, _level: int) -> void:
	_refresh(TimeManager.month, TimeManager.year)


func _on_rank_changed(_old: int, _new: int) -> void:
	_refresh(TimeManager.month, TimeManager.year)


func _on_disciples_changed(_id: String) -> void:
	_refresh(TimeManager.month, TimeManager.year)


func _on_recruit_pressed() -> void:
	_recruit_panel.open_panel()


func _get_rank_display(rank: int) -> String:
	var names = {9: "九品", 8: "八品", 7: "七品", 6: "六品", 5: "五品",
		4: "四品", 3: "三品", 2: "二品", 1: "一品", 0: "超品"}
	return "%s宗门" % names.get(rank, "?品")


func _get_task_display(task_id: String) -> String:
	var map = {
		"": "空闲", "idle": "空闲",
		"cultivating": "闭关修炼",
		"alchemy": "炼丹中",
		"crafting": "炼器中",
		"exploring": "秘境探索中",
		"guarding": "镇守山门",
		"teaching": "教导弟子",
		"market_work": "坊市打工",
		"herb_gathering": "采集灵草",
		"guard_caravan": "护送商队",
		"beast_hunting": "猎杀妖兽",
		"teach_wanderers": "教导散修",
	}
	return map.get(task_id, task_id)


func _get_disciple_focus_hint(disciple: Resource) -> String:
	var pct = int(clampf(disciple.cultivation_progress * 100.0, 0.0, 100.0))
	var realm_data = DataRegistry.cultivation_realms.get(disciple.realm, {})
	var sub_stages = realm_data.get("sub_stages", 1)
	if disciple.cultivation_progress >= 1.0:
		return "可尝试突破"
	if disciple.sub_realm >= sub_stages and disciple.realm == 1 and _has_item("foundation"):
		return "筑基丹已备，修为进度 %d%%" % pct
	return "修为进度 %d%%" % pct


func _get_monthly_stone_projection(sect: Resource) -> int:
	var income = 0
	var vein = sect.get_facility("spirit_vein")
	if vein:
		income += DataRegistry.facility_templates.get("spirit_vein", {}).get("stone_output", {}).get(vein.level, 0)
	for d in sect.disciples:
		if d.alive and d.assigned_task in DiscipleController.WORK_INCOME:
			var info = DiscipleController.WORK_INCOME[d.assigned_task]
			income += int((info["min"] + info["max"]) / 2)

	var upkeep = 0
	for facility in sect.facilities:
		upkeep += DataRegistry.facility_templates.get(facility.facility_type, {}).get("maintenance", {}).get(facility.level, 0)
	for d in sect.disciples:
		if d.alive:
			upkeep += SectController.get_position_salary(d.position)
		if d.alive and d.assigned_task in ["alchemy", "crafting"]:
			upkeep += DiscipleController.TASK_COSTS.get(d.assigned_task, 0)
	return income - upkeep


func _format_resource_dict(data: Dictionary) -> String:
	var parts: Array[String] = []
	for key in data:
		parts.append("%s %d" % [_get_resource_display_name(key), data[key]])
	return "，".join(parts)


func _get_resource_display_name(raw_id: String) -> String:
	var name_map = {
		"spirit_herb": "灵草", "ginseng": "人参", "lingzhi": "灵芝",
		"iron": "铁矿", "silk": "灵蚕丝", "jade": "灵玉",
	}
	return name_map.get(raw_id, raw_id)


func _count_inventory_by_type(sect: Resource, item_type: int) -> int:
	var total = 0
	for item in sect.inventory:
		if item.item_type == item_type:
			total += item.quantity
	return total


func _has_item(item_id: String) -> bool:
	var sect = GameManager.current_sect
	if not sect:
		return false
	for item in sect.inventory:
		if item.item_id == item_id and item.quantity > 0:
			return true
	return false


func _get_recent_memories(sect: Resource, limit: int) -> Array[String]:
	var result: Array[String] = []
	for d in sect.disciples:
		for memory in d.life_memories:
			result.append("%s：%s" % [d.disciple_name, memory])
	result.reverse()
	return result.slice(0, limit)
