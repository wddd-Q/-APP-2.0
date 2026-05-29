class_name DiscipleRosterPanel
extends Control
## 弟子名册 — 人员状态、性格故事、任职风险的总览界面

const DisciplePortrait = preload("res://src/ui/disciple_portrait.gd")

var _detail_panel: DiscipleDetailPanel
var _recruit_panel: DiscipleRecruitPanel
var _summary_label: RichTextLabel
var _search_box: LineEdit
var _filter_option: OptionButton
var _sort_option: OptionButton
var _list: VBoxContainer
var _preview: RichTextLabel
var _selected_disciple_id: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_detail_panel = get_node_or_null("../../../DiscipleDetailPanel")
	_recruit_panel = get_node_or_null("../../../DiscipleRecruitPanel")
	_build_ui()
	EventBus.game_started.connect(_on_data_changed)
	EventBus.month_passed.connect(_on_data_changed)
	EventBus.disciple_recruited.connect(_on_data_changed)
	EventBus.disciple_died.connect(_on_data_changed)
	EventBus.disciple_task_assigned.connect(_on_data_changed)
	EventBus.position_changed.connect(_on_data_changed)
	EventBus.disciple_broken_through.connect(_on_data_changed)
	if GameManager.current_sect:
		_refresh()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)

	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title = Label.new()
	title.text = "弟子名册"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.92, 0.82, 0.48, 1.0))
	title_box.add_child(title)

	_summary_label = RichTextLabel.new()
	_summary_label.bbcode_enabled = true
	_summary_label.fit_content = true
	_summary_label.scroll_active = false
	_summary_label.custom_minimum_size = Vector2(0, 52)
	_summary_label.add_theme_font_size_override("normal_font_size", 15)
	title_box.add_child(_summary_label)

	var recruit_btn = Button.new()
	recruit_btn.text = "招收弟子"
	recruit_btn.custom_minimum_size = Vector2(120, 40)
	recruit_btn.add_theme_font_size_override("font_size", 16)
	recruit_btn.pressed.connect(func():
		if _recruit_panel:
			_recruit_panel.open_panel()
	)
	header.add_child(recruit_btn)

	var tools = HBoxContainer.new()
	tools.add_theme_constant_override("separation", 10)
	root.add_child(tools)

	_search_box = LineEdit.new()
	_search_box.placeholder_text = "搜索姓名、擅长、性格、来历"
	_search_box.custom_minimum_size = Vector2(300, 34)
	_search_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_box.text_changed.connect(func(_text: String): _refresh())
	tools.add_child(_search_box)

	_filter_option = OptionButton.new()
	_filter_option.custom_minimum_size = Vector2(160, 34)
	_add_filter_options()
	_filter_option.item_selected.connect(func(_idx: int): _refresh())
	tools.add_child(_filter_option)

	_sort_option = OptionButton.new()
	_sort_option.custom_minimum_size = Vector2(160, 34)
	_add_sort_options()
	_sort_option.item_selected.connect(func(_idx: int): _refresh())
	tools.add_child(_sort_option)

	var body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var list_panel = PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(620, 0)
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(list_panel)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var preview_panel = PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(390, 0)
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(preview_panel)

	_preview = RichTextLabel.new()
	_preview.bbcode_enabled = true
	_preview.fit_content = false
	_preview.add_theme_font_size_override("normal_font_size", 15)
	preview_panel.add_child(_preview)


func _add_filter_options() -> void:
	_filter_option.clear()
	var options = [
		["全部弟子", "all"],
		["可突破", "breakthrough"],
		["任职弟子", "officers"],
		["外派/远行", "away"],
		["空闲", "idle"],
		["有风险", "risk"],
	]
	for option in options:
		_filter_option.add_item(option[0])
		_filter_option.set_item_metadata(_filter_option.item_count - 1, option[1])


func _add_sort_options() -> void:
	_sort_option.clear()
	var options = [
		["境界优先", "realm"],
		["潜力优先", "potential"],
		["任务分组", "task"],
		["风险优先", "risk"],
	]
	for option in options:
		_sort_option.add_item(option[0])
		_sort_option.set_item_metadata(_sort_option.item_count - 1, option[1])


func _refresh() -> void:
	var sect = GameManager.current_sect
	if not sect:
		return
	_update_summary(sect)
	_refresh_list(sect)
	_refresh_preview(sect)


func _update_summary(sect: Resource) -> void:
	var alive = 0
	var officers = 0
	var ready = 0
	var risk = 0
	var away = 0
	var loyalty_total = 0
	for d in sect.disciples:
		if not d.alive:
			continue
		alive += 1
		loyalty_total += int(d.loyalty)
		if d.position != "普通弟子":
			officers += 1
		if d.cultivation_progress >= 1.0:
			ready += 1
		if _get_risk_score(d) >= 45:
			risk += 1
		if _is_away(d):
			away += 1

	_summary_label.clear()
	var average_loyalty = int(float(loyalty_total) / maxf(1.0, float(alive)))
	_summary_label.append_text("弟子 [color=#d9c85f]%d/%d[/color]  平均忠诚 [color=#d9c85f]%d[/color]  任职 [color=#d9c85f]%d[/color]  可突破 [color=#d9c85f]%d[/color]  外派 [color=#d9c85f]%d[/color]  风险关注 [color=#d9c85f]%d[/color]" % [
		alive,
		sect.max_disciples(),
		average_loyalty,
		officers,
		ready,
		away,
		risk,
	])


func _refresh_list(sect: Resource) -> void:
	for child in _list.get_children():
		child.queue_free()

	var disciples = _get_filtered_sorted_disciples(sect)
	if disciples.is_empty():
		var empty = Label.new()
		empty.text = "当前条件下没有弟子"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color(0.75, 0.68, 0.52, 1.0))
		_list.add_child(empty)
		return

	if _selected_disciple_id.is_empty() or not _has_disciple_id(disciples, _selected_disciple_id):
		_selected_disciple_id = disciples[0].disciple_id

	for d in disciples:
		_list.add_child(_make_disciple_row(d))


func _make_disciple_row(d: DiscipleData) -> Control:
	var row_panel = PanelContainer.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.095, 0.065, 0.88) if d.disciple_id == _selected_disciple_id else Color(0.075, 0.06, 0.045, 0.74)
	style.border_color = Color(0.72, 0.58, 0.25, 0.82) if d.disciple_id == _selected_disciple_id else Color(0.28, 0.22, 0.12, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	row_panel.add_theme_stylebox_override("panel", style)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row_panel.add_child(row)

	var portrait = DisciplePortrait.new()
	portrait.setup(d, 54)
	row.add_child(portrait)

	var main = VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 4)
	row.add_child(main)

	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	main.add_child(top)

	var name = Label.new()
	name.text = "%s  %s" % [d.disciple_name, _get_gender_text(d.gender)]
	name.add_theme_font_size_override("font_size", 18)
	name.add_theme_color_override("font_color", Color(0.92, 0.84, 0.62, 1.0))
	top.add_child(name)

	var realm = Label.new()
	realm.text = "%s%d层" % [DataRegistry.get_realm_name(d.realm), d.sub_realm]
	realm.add_theme_color_override("font_color", Color(0.72, 0.86, 0.95, 1.0))
	top.add_child(realm)

	var status = Label.new()
	status.text = _get_status_tag(d)
	status.add_theme_color_override("font_color", _get_status_color(d))
	top.add_child(status)

	var line = Label.new()
	line.text = "%s | %s | %s | %s | %s" % [
		d.position,
		_get_task_display(d.assigned_task),
		"忠诚%d" % d.loyalty,
		d.specialty if d.specialty != "" else "擅长未明",
		"、".join(d.personalities) if not d.personalities.is_empty() else "性格未明",
	]
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_font_size_override("font_size", 14)
	line.add_theme_color_override("font_color", Color(0.78, 0.72, 0.58, 1.0))
	main.add_child(line)

	var progress = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = 100
	progress.value = clampf(d.cultivation_progress * 100.0, 0.0, 100.0)
	progress.custom_minimum_size = Vector2(0, 10)
	progress.show_percentage = false
	main.add_child(progress)

	var action_box = VBoxContainer.new()
	action_box.custom_minimum_size = Vector2(96, 0)
	row.add_child(action_box)

	var select_btn = Button.new()
	select_btn.text = "查看"
	select_btn.pressed.connect(func():
		_selected_disciple_id = d.disciple_id
		_refresh()
	)
	action_box.add_child(select_btn)

	var detail_btn = Button.new()
	detail_btn.text = "详情"
	detail_btn.pressed.connect(func():
		_selected_disciple_id = d.disciple_id
		_refresh_preview(GameManager.current_sect)
		if _detail_panel:
			_detail_panel.show_disciple(d)
	)
	action_box.add_child(detail_btn)

	return row_panel


func _refresh_preview(sect: Resource) -> void:
	if not _preview:
		return
	var d = _find_disciple(sect, _selected_disciple_id)
	_preview.clear()
	if not d:
		_preview.append_text("[b]未选择弟子[/b]\n从左侧名册选择一名弟子。")
		return

	_preview.append_text("[font_size=22][color=#e8d17a]%s[/color][/font_size]\n" % d.disciple_name)
	_preview.append_text("%s  %d岁/%d寿元  %s\n" % [
		_get_gender_text(d.gender),
		d.age,
		d.lifespan,
		DataRegistry.spirit_roots.get(d.spirit_root_quality, {}).get("name", "未知灵根"),
	])
	_preview.append_text("境界: %s%d层  修为%d%%\n" % [
		DataRegistry.get_realm_name(d.realm),
		d.sub_realm,
		int(clampf(d.cultivation_progress * 100.0, 0.0, 100.0)),
	])
	_preview.append_text("职位: %s  任务: %s  忠诚: %d\n\n" % [d.position, _get_task_display(d.assigned_task), d.loyalty])

	_preview.append_text("[b]性格与判断倾向[/b]\n")
	_preview.append_text("%s\n" % _get_personality_reading(d))
	_preview.append_text("风险评估: %s\n\n" % _get_risk_text(d))

	_preview.append_text("[b]擅长[/b]\n")
	_preview.append_text("%s\n" % (d.specialty if d.specialty != "" else "暂无明确擅长"))
	_preview.append_text("最高属性: %s\n" % _get_best_attribute_text(d))
	_preview.append_text("最高技能: %s\n\n" % _get_best_skill_text(d))

	_preview.append_text("[b]来历[/b]\n")
	_preview.append_text("%s\n\n" % (d.origin_story if d.origin_story != "" else "此弟子来历尚未整理。"))

	_preview.append_text("[b]近期记忆[/b]\n")
	if d.life_memories.is_empty():
		_preview.append_text("尚无重要人生记录")
	else:
		var start = maxi(0, d.life_memories.size() - 5)
		for memory in d.life_memories.slice(start, d.life_memories.size()):
			_preview.append_text("  - %s\n" % memory)


func _get_filtered_sorted_disciples(sect: Resource) -> Array:
	var result: Array = []
	var filter_id = _filter_option.get_item_metadata(_filter_option.selected) if _filter_option.selected >= 0 else "all"
	var query = _search_box.text.strip_edges().to_lower()

	for d in sect.disciples:
		if not d.alive:
			continue
		if not _passes_filter(d, filter_id):
			continue
		if not query.is_empty() and not _matches_query(d, query):
			continue
		result.append(d)

	var sort_id = _sort_option.get_item_metadata(_sort_option.selected) if _sort_option.selected >= 0 else "realm"
	match sort_id:
		"potential":
			result.sort_custom(func(a, b): return _get_potential_score(a) > _get_potential_score(b))
		"task":
			result.sort_custom(func(a, b): return _get_task_display(a.assigned_task) < _get_task_display(b.assigned_task))
		"risk":
			result.sort_custom(func(a, b): return _get_risk_score(a) > _get_risk_score(b))
		_:
			result.sort_custom(func(a, b):
				var ap = a.realm * 1000 + a.sub_realm * 100 + int(a.cultivation_progress * 100.0)
				var bp = b.realm * 1000 + b.sub_realm * 100 + int(b.cultivation_progress * 100.0)
				return ap > bp
			)
	return result


func _passes_filter(d: Resource, filter_id: String) -> bool:
	match filter_id:
		"breakthrough":
			return d.cultivation_progress >= 1.0
		"officers":
			return d.position != "普通弟子"
		"away":
			return _is_away(d)
		"idle":
			return d.assigned_task in ["", "idle"]
		"risk":
			return _get_risk_score(d) >= 45
		_:
			return true


func _matches_query(d: Resource, query: String) -> bool:
	var haystack = "%s %s %s %s %s" % [
		d.disciple_name,
		d.specialty,
		d.origin_story,
		" ".join(d.personalities),
		_get_task_display(d.assigned_task),
	]
	return haystack.to_lower().contains(query)


func _has_disciple_id(disciples: Array, id: String) -> bool:
	for d in disciples:
		if d.disciple_id == id:
			return true
	return false


func _find_disciple(sect: Resource, id: String) -> Resource:
	if not sect:
		return null
	for d in sect.disciples:
		if d.disciple_id == id and d.alive:
			return d
	return null


func _is_away(d: Resource) -> bool:
	return d.location in ["exploring", "mission"] or d.assigned_task in ["exploring", "market_work", "guard_caravan", "beast_hunting", "teach_wanderers"]


func _get_gender_text(gender: int) -> String:
	return "男" if gender == 0 else "女"


func _get_status_tag(d: Resource) -> String:
	if d.cultivation_progress >= 1.0:
		return "可突破"
	if _get_risk_score(d) >= 55:
		return "需关注"
	if _is_away(d):
		return "外派"
	return "在宗"


func _get_status_color(d: Resource) -> Color:
	if d.cultivation_progress >= 1.0:
		return Color(0.92, 0.78, 0.28, 1.0)
	if _get_risk_score(d) >= 55:
		return Color(0.95, 0.42, 0.35, 1.0)
	if _is_away(d):
		return Color(0.56, 0.78, 0.95, 1.0)
	return Color(0.58, 0.86, 0.62, 1.0)


func _get_risk_score(d: Resource) -> int:
	var score = 15
	if "忠诚" in d.personalities:
		score -= 18
	if "谨慎" in d.personalities or "善良" in d.personalities:
		score -= 8
	if "贪婪" in d.personalities:
		score += 25
	if "阴狠" in d.personalities:
		score += 22
	if "孤傲" in d.personalities:
		score += 12
	if d.mentality < 35:
		score += 18
	if d.fortune < 35:
		score += 6
	score += int((50 - int(d.loyalty)) * 0.7)
	if d.position != "普通弟子":
		score -= 5
	return clampi(score, 0, 100)


func _get_risk_text(d: Resource) -> String:
	var score = _get_risk_score(d)
	if score >= 70:
		return "[color=#e86b5a]高，需要掌门留意其利益诉求与事件处理倾向。[/color]"
	if score >= 45:
		return "[color=#d9c85f]中，适合观察后再委派关键事务。[/color]"
	return "[color=#75d17c]低，当前较稳定。[/color]"


func _get_personality_reading(d: Resource) -> String:
	if d.personalities.is_empty():
		return "性格尚不明显，事件处理倾向难以判断。"
	var parts: Array[String] = []
	for personality in d.personalities:
		match personality:
			"勇猛":
				parts.append("遇敌更倾向迎战")
			"谨慎":
				parts.append("处理事务偏稳妥")
			"贪婪":
				parts.append("更容易被利益诱导")
			"忠诚":
				parts.append("更重视宗门立场")
			"孤傲":
				parts.append("不喜受人约束")
			"好奇":
				parts.append("适合探秘和发现线索")
			"善良":
				parts.append("更愿意保护弱者")
			"阴狠":
				parts.append("处置冲突可能偏激")
			"豪爽":
				parts.append("擅长结交外部修士")
			"内敛":
				parts.append("适合静修和长期任务")
			_:
				parts.append(personality)
	return "、".join(parts) + "。"


func _get_potential_score(d: Resource) -> int:
	return d.bone_structure + d.comprehension + d.talent + int(d.fortune * 0.5) + int(d.mentality * 0.5)


func _get_best_attribute_text(d: Resource) -> String:
	var attrs = {
		"根骨": d.bone_structure,
		"悟性": d.comprehension,
		"福缘": d.fortune,
		"心性": d.mentality,
		"魅力": d.charm,
		"资质": d.talent,
	}
	var best_name = "未知"
	var best_value = -1
	for key in attrs:
		if attrs[key] > best_value:
			best_name = key
			best_value = attrs[key]
	return "%s %d" % [best_name, best_value]


func _get_best_skill_text(d: Resource) -> String:
	var names = {
		"alchemy": "炼丹",
		"crafting": "炼器",
		"formation": "阵法",
		"beast_taming": "御兽",
		"talisman": "符箓",
		"medicine": "医术",
	}
	var best_key = ""
	var best_value = -1
	for key in d.skills:
		if int(d.skills[key]) > best_value:
			best_key = key
			best_value = int(d.skills[key])
	if best_value <= 0:
		return "暂无成型技能"
	return "%s %d" % [names.get(best_key, best_key), best_value]


func _get_task_display(task_id: String) -> String:
	var map = {
		"": "空闲", "idle": "空闲",
		"cultivating": "闭关修炼",
		"alchemy": "炼丹",
		"crafting": "炼器",
		"exploring": "秘境探索",
		"guarding": "镇守山门",
		"teaching": "教导弟子",
		"market_work": "坊市打工",
		"herb_gathering": "采集灵草",
		"guard_caravan": "护送商队",
		"beast_hunting": "猎杀妖兽",
		"teach_wanderers": "教导散修",
	}
	return map.get(task_id, task_id)


func _on_data_changed(_a = null, _b = null, _c = null) -> void:
	if is_inside_tree():
		_refresh()
