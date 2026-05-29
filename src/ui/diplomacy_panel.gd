class_name DiplomacyPanel
extends Control
## 天下势力面板：排行榜、差距条、宗门情报

const DisciplePortrait = preload("res://src/ui/disciple_portrait.gd")

var _ranking_list: VBoxContainer
var _summary_label: Label
var _detail_title: Label
var _detail_meta: Label
var _metric_container: VBoxContainer
var _recommendation_label: Label
var _npc_disciples_container: VBoxContainer
var _selected_name: String = ""


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.68)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			visible = false
	)
	add_child(bg)

	var panel = Panel.new()
	panel.size = Vector2(1120, 720)
	panel.position = Vector2(get_viewport().get_visible_rect().size / 2 - panel.size / 2)
	add_child(panel)

	var root = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18
	root.offset_top = 14
	root.offset_right = -18
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var title = Label.new()
	title.text = "天下宗门榜"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.93, 0.82, 0.48, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(96, 42)
	close_btn.pressed.connect(func(): visible = false)
	header.add_child(close_btn)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.add_theme_font_size_override("font_size", 17)
	_summary_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.64, 1.0))
	root.add_child(_summary_label)

	var body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	var left = VBoxContainer.new()
	left.custom_minimum_size = Vector2(500, 0)
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)

	var left_title = Label.new()
	left_title.text = "实时排名"
	left_title.add_theme_font_size_override("font_size", 20)
	left_title.add_theme_color_override("font_color", Color(0.9, 0.84, 0.58, 1.0))
	left.add_child(left_title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)

	_ranking_list = VBoxContainer.new()
	_ranking_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_ranking_list)

	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)

	_detail_title = Label.new()
	_detail_title.text = "选择一个宗门查看差距"
	_detail_title.add_theme_font_size_override("font_size", 22)
	_detail_title.add_theme_color_override("font_color", Color(0.93, 0.82, 0.48, 1.0))
	right.add_child(_detail_title)

	_detail_meta = Label.new()
	_detail_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_meta.add_theme_font_size_override("font_size", 16)
	right.add_child(_detail_meta)

	_metric_container = VBoxContainer.new()
	_metric_container.add_theme_constant_override("separation", 8)
	right.add_child(_metric_container)

	_recommendation_label = Label.new()
	_recommendation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recommendation_label.add_theme_font_size_override("font_size", 15)
	_recommendation_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.64, 1.0))
	right.add_child(_recommendation_label)

	var disciple_title = Label.new()
	disciple_title.text = "核心弟子情报"
	disciple_title.add_theme_font_size_override("font_size", 17)
	disciple_title.add_theme_color_override("font_color", Color(0.9, 0.84, 0.58, 1.0))
	right.add_child(disciple_title)

	var npc_scroll = ScrollContainer.new()
	npc_scroll.custom_minimum_size = Vector2(0, 170)
	npc_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(npc_scroll)

	_npc_disciples_container = VBoxContainer.new()
	_npc_disciples_container.add_theme_constant_override("separation", 6)
	npc_scroll.add_child(_npc_disciples_container)


func open_panel() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	for child in _ranking_list.get_children():
		child.queue_free()

	var rankings = WorldController.get_power_rankings()
	if rankings.is_empty():
		_summary_label.text = "暂无天下势力情报。"
		return

	var summary = WorldController.get_player_ranking_summary()
	_summary_label.text = _format_summary(summary)

	for entry in rankings:
		_ranking_list.add_child(_make_rank_card(entry))

	var selected = _find_entry(rankings, _selected_name)
	if selected.is_empty():
		selected = summary.get("entry", rankings[0])
	_show_entry_detail(selected)


func _make_rank_card(entry: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_style(entry.get("is_player", false), entry.get("name", "") == _selected_name))

	var btn = Button.new()
	btn.flat = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 82)
	btn.text = "#%d  %s%s\n综合 %d  |  %s  |  战力 %d  |  声望 %d  |  灵石 %d" % [
		entry.get("world_rank", 0),
		entry.get("name", ""),
		"（本宗门）" if entry.get("is_player", false) else "",
		entry.get("score", 0),
		_rank_name(entry.get("rank_grade", 9)),
		entry.get("combat_power", 0),
		entry.get("prestige", 0),
		entry.get("spirit_stones", 0),
	]
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(0.92, 0.88, 0.76, 1.0))
	var name = entry.get("name", "")
	btn.pressed.connect(func():
		_selected_name = name
		_show_entry_detail(entry)
		_refresh()
	)
	card.add_child(btn)
	return card


func _show_entry_detail(entry: Dictionary) -> void:
	if entry.is_empty():
		return

	_selected_name = entry.get("name", "")
	for child in _metric_container.get_children():
		child.queue_free()
	for child in _npc_disciples_container.get_children():
		child.queue_free()

	var summary = WorldController.get_player_ranking_summary()
	var player = summary.get("entry", {})
	var target = entry
	if entry.get("is_player", false):
		target = summary.get("above", {})
		if target.is_empty():
			target = summary.get("leader", entry)

	_detail_title.text = "%s%s" % [entry.get("name", ""), "（本宗门）" if entry.get("is_player", false) else ""]
	_detail_meta.text = "%s | 最高境界 %s | 阵营 %s | 关系 %s" % [
		_rank_name(entry.get("rank_grade", 9)),
		DataRegistry.get_realm_name(entry.get("realm", 1)),
		_camp_text(entry.get("karma", 0)),
		_relation_text(entry.get("relation", 0)) if not entry.get("is_player", false) else "自身",
	]

	if not target.is_empty():
		var target_name = target.get("name", "目标")
		_add_metric_row("综合", player.get("score", 0), target.get("score", 0), target_name)
		_add_metric_row("战力", player.get("combat_power", 0), target.get("combat_power", 0), target_name)
		_add_metric_row("声望", player.get("prestige", 0), target.get("prestige", 0), target_name)
		_add_metric_row("灵石", player.get("spirit_stones", 0), target.get("spirit_stones", 0), target_name)
		_add_metric_row("弟子", player.get("disciple_count", 0), target.get("disciple_count", 0), target_name)
		_add_metric_row("境界", player.get("realm", 1), target.get("realm", 1), target_name)
		_recommendation_label.text = _make_recommendation(player, target)
	else:
		_recommendation_label.text = "当前没有可对比目标。"

	var faction = entry.get("faction", null)
	if faction:
		_refresh_npc_disciples(faction)
	else:
		var hint = Label.new()
		hint.text = "本宗门弟子请在主界面弟子名册查看。"
		hint.add_theme_color_override("font_color", Color(0.72, 0.68, 0.55, 1.0))
		_npc_disciples_container.add_child(hint)


func _add_metric_row(title: String, player_value: int, target_value: int, target_name: String) -> void:
	var row = VBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var diff = player_value - target_value
	var label = Label.new()
	label.text = "%s：本宗门 %d / %s %d（%s）" % [
		title,
		player_value,
		target_name,
		target_value,
		_gap_text(diff),
	]
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.9, 0.86, 0.72, 1.0) if diff >= 0 else Color(0.95, 0.58, 0.45, 1.0))
	row.add_child(label)

	var bars = HBoxContainer.new()
	bars.add_theme_constant_override("separation", 6)
	row.add_child(bars)

	var max_value = max(1, maxi(player_value, target_value))
	bars.add_child(_make_progress_bar(player_value, max_value, Color(0.34, 0.72, 0.48, 1.0)))
	bars.add_child(_make_progress_bar(target_value, max_value, Color(0.78, 0.58, 0.24, 1.0)))

	_metric_container.add_child(row)


func _make_progress_bar(value: int, max_value: int, color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = max_value
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.07, 0.05, 0.9)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)

	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _refresh_npc_disciples(faction: FactionData) -> void:
	if faction.disciples.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无弟子情报"
		lbl.add_theme_color_override("font_color", Color.GRAY)
		_npc_disciples_container.add_child(lbl)
		return

	var sorted = faction.disciples.duplicate()
	sorted.sort_custom(func(a, b): return a["realm"] > b["realm"] or (a["realm"] == b["realm"] and a["sub_realm"] > b["sub_realm"]))

	for disc in sorted.slice(0, 6):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var temp_d = DiscipleData.new()
		temp_d.disciple_name = disc["name"]
		temp_d.spirit_root_quality = disc["spirit_root_quality"]
		temp_d.spirit_elements = disc["spirit_elements"]
		temp_d.realm = disc["realm"]

		var portrait = DisciplePortrait.new()
		portrait.setup(temp_d, 30)
		row.add_child(portrait)

		var info = Label.new()
		info.text = "%s | %s%d层 | %s | %d岁" % [
			disc["name"],
			DataRegistry.get_realm_name(disc["realm"]),
			disc["sub_realm"],
			disc.get("spirit_root_name", "?灵根"),
			disc["age"],
		]
		info.add_theme_font_size_override("font_size", 13)
		row.add_child(info)
		_npc_disciples_container.add_child(row)


func _format_summary(summary: Dictionary) -> String:
	if summary.is_empty():
		return "本宗门尚未进入天下榜。"
	var entry = summary.get("entry", {})
	var above = summary.get("above", {})
	if above.is_empty():
		return "本宗门当前位列天下第 %d / %d，暂居榜首。综合实力 %d。" % [
			summary.get("rank", 0),
			summary.get("total", 0),
			entry.get("score", 0),
		]
	return "本宗门当前位列天下第 %d / %d，综合实力 %d；距上一名「%s」还差 %d 点。" % [
		summary.get("rank", 0),
		summary.get("total", 0),
		entry.get("score", 0),
		above.get("name", ""),
		summary.get("score_gap", 0),
	]


func _make_recommendation(player: Dictionary, target: Dictionary) -> String:
	var gaps: Array = [
		{"name": "战力", "gap": int(target.get("combat_power", 0) - player.get("combat_power", 0)), "hint": "安排核心弟子闭关、突破，或提升斗法相关设施。"},
		{"name": "声望", "gap": int(target.get("prestige", 0) - player.get("prestige", 0)), "hint": "完成秘境、事件和对外行动，先把名声打出去。"},
		{"name": "灵石", "gap": int(target.get("spirit_stones", 0) - player.get("spirit_stones", 0)), "hint": "优先升级灵脉，减少低收益开支，派弟子进行稳定营生。"},
		{"name": "弟子", "gap": int(target.get("disciple_count", 0) - player.get("disciple_count", 0)), "hint": "扩充弟子名额并持续招收，避免只有少数核心撑场。"},
		{"name": "境界", "gap": int(target.get("realm", 1) - player.get("realm", 1)), "hint": "集中资源培养最高境界弟子，先做出一个门面人物。"},
	]
	gaps.sort_custom(func(a, b): return a["gap"] > b["gap"])
	for item in gaps:
		if item["gap"] > 0:
			return "短板建议：当前最明显差距是%s，差 %d。%s" % [item["name"], item["gap"], item["hint"]]
	return "当前对比目标已无明显优势，可以考虑主动外交、秘境竞争或冲击更高品级。"


func _find_entry(rankings: Array, entry_name: String) -> Dictionary:
	if entry_name.is_empty():
		return {}
	for entry in rankings:
		if entry.get("name", "") == entry_name:
			return entry
	return {}


func _make_card_style(is_player: bool, is_selected: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.19, 0.14, 0.08, 0.86) if is_player else Color(0.08, 0.07, 0.05, 0.72)
	if is_selected:
		style.bg_color = Color(0.24, 0.18, 0.1, 0.92)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.68, 0.54, 0.22, 1.0) if is_player or is_selected else Color(0.34, 0.28, 0.15, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _rank_name(rank: int) -> String:
	var names = {9: "九品", 8: "八品", 7: "七品", 6: "六品", 5: "五品", 4: "四品", 3: "三品", 2: "二品", 1: "一品", 0: "超品"}
	return names.get(rank, "?品")


func _camp_text(value: int) -> String:
	if value > 20:
		return "正道"
	if value < -20:
		return "魔道"
	return "中立"


func _relation_text(value: int) -> String:
	if value >= 60: return "同盟"
	if value >= 30: return "友好"
	if value >= 0: return "中立"
	if value >= -30: return "紧张"
	if value >= -60: return "敌对"
	return "死敌"


func _gap_text(value: int) -> String:
	if value > 0:
		return "+%d" % value
	if value == 0:
		return "持平"
	return "%d" % value
