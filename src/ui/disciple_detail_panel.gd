class_name DiscipleDetailPanel
extends Control
## 弟子详情面板 — 完整属性、技能、关系、记忆


const DisciplePortrait = preload("res://src/ui/disciple_portrait.gd")
const StatRadarChart = preload("res://src/ui/stat_radar_chart.gd")

var _current_disciple: DiscipleData = null

var _portrait: DisciplePortrait
var _name_label: Label
var _realm_label: Label
var _attributes_grid: GridContainer
var _skills_grid: GridContainer
var _attr_chart: StatRadarChart
var _skill_chart: StatRadarChart
var _personalities_label: Label
var _relationships_list: VBoxContainer
var _memories_list: VBoxContainer
var _task_option: OptionButton
var _position_option: OptionButton


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func _build_ui() -> void:
	# 半透明背景遮罩（点击关闭）
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			visible = false
	)
	add_child(bg)

	# 主面板 — 使用 MarginContainer 固定尺寸
	var panel = Panel.new()
	panel.size = Vector2(720, 620)
	panel.position = Vector2(get_viewport().get_visible_rect().size / 2 - panel.size / 2)
	add_child(panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(main_vbox)

	# === 标题栏（带头像 + 关闭按钮）===
	var title_bar = HBoxContainer.new()
	title_bar.add_theme_constant_override("separation", 10)
	main_vbox.add_child(title_bar)

	_portrait = DisciplePortrait.new()
	title_bar.add_child(_portrait)

	var name_realm = VBoxContainer.new()
	title_bar.add_child(name_realm)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 26)
	name_realm.add_child(_name_label)

	_realm_label = Label.new()
	_realm_label.add_theme_font_size_override("font_size", 18)
	name_realm.add_child(_realm_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.pressed.connect(func(): visible = false)
	title_bar.add_child(close_btn)

	# === 滚动内容 ===
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 500)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	# === 六维属性（雷达图 + 数值并排）===
	content.add_child(_make_section("六维属性"))
	var attr_row = HBoxContainer.new()
	attr_row.add_theme_constant_override("separation", 20)
	content.add_child(attr_row)

	_attr_chart = StatRadarChart.new()
	_attr_chart.custom_minimum_size = Vector2(180, 180)
	attr_row.add_child(_attr_chart)

	_attributes_grid = GridContainer.new()
	_attributes_grid.columns = 2
	_attributes_grid.add_theme_constant_override("h_separation", 20)
	_attributes_grid.add_theme_constant_override("v_separation", 4)
	attr_row.add_child(_attributes_grid)

	# === 技能（雷达图 + 数值并排）===
	content.add_child(_make_section("技能"))
	var skill_row = HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 20)
	content.add_child(skill_row)

	_skill_chart = StatRadarChart.new()
	_skill_chart.custom_minimum_size = Vector2(180, 180)
	skill_row.add_child(_skill_chart)

	_skills_grid = GridContainer.new()
	_skills_grid.columns = 2
	_skills_grid.add_theme_constant_override("h_separation", 20)
	_skills_grid.add_theme_constant_override("v_separation", 4)
	skill_row.add_child(_skills_grid)

	# === 人格 ===
	content.add_child(_make_section("人格"))
	_personalities_label = Label.new()
	content.add_child(_personalities_label)

	# === 关系 ===
	content.add_child(_make_section("关系"))
	_relationships_list = VBoxContainer.new()
	content.add_child(_relationships_list)

	# === 记忆 ===
	content.add_child(_make_section("记忆"))
	_memories_list = VBoxContainer.new()
	content.add_child(_memories_list)

	# === 底部操作 ===
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 15)
	main_vbox.add_child(actions)

	var pos_label = Label.new()
	pos_label.text = "职位:"
	pos_label.add_theme_font_size_override("font_size", 16)
	actions.add_child(pos_label)

	_position_option = OptionButton.new()
	_position_option.add_theme_font_size_override("font_size", 14)
	_position_option.item_selected.connect(_on_position_changed)
	actions.add_child(_position_option)

	var task_label = Label.new()
	task_label.text = "  任务:"
	task_label.add_theme_font_size_override("font_size", 16)
	actions.add_child(task_label)

	_task_option = OptionButton.new()
	_task_option.add_theme_font_size_override("font_size", 14)
	_populate_task_options()
	_task_option.item_selected.connect(_on_task_changed)
	actions.add_child(_task_option)

	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer2)

	var close_button2 = Button.new()
	close_button2.text = "关闭"
	close_button2.pressed.connect(func(): visible = false)
	actions.add_child(close_button2)


func _make_section(title: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 5)
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	section.add_child(title_lbl)
	return section


func show_disciple(disciple: DiscipleData) -> void:
	_current_disciple = disciple
	visible = true
	_refresh_all()


func _refresh_all() -> void:
	if not _current_disciple:
		return

	_portrait.setup(_current_disciple, 64)
	_name_label.text = _current_disciple.disciple_name
	var realm_name = DataRegistry.get_realm_name(_current_disciple.realm)
	_realm_label.text = "%s %d层 | %d岁/%d寿元" % [
		realm_name,
		_current_disciple.sub_realm,
		_current_disciple.age,
		_current_disciple.lifespan,
	]

	_refresh_grid(_attributes_grid, [
		["根骨", _current_disciple.bone_structure],
		["悟性", _current_disciple.comprehension],
		["福缘", _current_disciple.fortune],
		["心性", _current_disciple.mentality],
		["魅力", _current_disciple.charm],
		["资质", _current_disciple.talent],
	])

	_attr_chart.setup(
		["根骨", "悟性", "福缘", "心性", "魅力", "资质"],
		[float(_current_disciple.bone_structure), float(_current_disciple.comprehension), float(_current_disciple.fortune),
		 float(_current_disciple.mentality), float(_current_disciple.charm), float(_current_disciple.talent)],
		Color(0.3, 0.7, 1.0, 0.3),
		Color(0.3, 0.7, 1.0, 0.8)
	)

	_refresh_grid(_skills_grid, [
		["炼丹", _current_disciple.skills.get("alchemy", 0)],
		["炼器", _current_disciple.skills.get("crafting", 0)],
		["阵法", _current_disciple.skills.get("formation", 0)],
		["御兽", _current_disciple.skills.get("beast_taming", 0)],
		["符箓", _current_disciple.skills.get("talisman", 0)],
		["医术", _current_disciple.skills.get("medicine", 0)],
	])

	_skill_chart.setup(
		["炼丹", "炼器", "阵法", "御兽", "符箓", "医术"],
		[float(_current_disciple.skills.get("alchemy", 0)), float(_current_disciple.skills.get("crafting", 0)),
		 float(_current_disciple.skills.get("formation", 0)), float(_current_disciple.skills.get("beast_taming", 0)),
		 float(_current_disciple.skills.get("talisman", 0)), float(_current_disciple.skills.get("medicine", 0))],
		Color(0.2, 0.8, 0.3, 0.3),
		Color(0.2, 0.8, 0.3, 0.8)
	)

	_personalities_label.text = "人格: " + (", ".join(_current_disciple.personalities) if _current_disciple.personalities else "无明显特征")

	_refresh_relationships()
	_refresh_memories()
	_refresh_position_selector()
	_task_option_update()


func _refresh_grid(grid: GridContainer, data: Array) -> void:
	for child in grid.get_children():
		child.queue_free()

	for pair in data:
		var name_lbl = Label.new()
		name_lbl.text = pair[0]
		grid.add_child(name_lbl)

		var val_lbl = Label.new()
		val_lbl.text = str(pair[1])
		if pair[1] >= 80:
			val_lbl.add_theme_color_override("font_color", Color.GOLD)
		elif pair[1] >= 60:
			val_lbl.add_theme_color_override("font_color", Color.GREEN)
		elif pair[1] < 30:
			val_lbl.add_theme_color_override("font_color", Color.RED)
		grid.add_child(val_lbl)


func _refresh_relationships() -> void:
	for child in _relationships_list.get_children():
		child.queue_free()

	if _current_disciple.relationships.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无特殊关系"
		_relationships_list.add_child(lbl)
		return

	for rel in _current_disciple.relationships:
		var lbl = Label.new()
		var type_name = {"master": "师父", "partner": "道侣", "friend": "挚友", "enemy": "仇敌"}.get(rel.get("type", ""), "熟人")
		lbl.text = "%s: %s (%d)" % [type_name, rel.get("target_id", "?"), rel.get("strength", 0)]
		_relationships_list.add_child(lbl)


func _refresh_memories() -> void:
	for child in _memories_list.get_children():
		child.queue_free()

	var memories = _current_disciple.life_memories
	if memories.is_empty():
		var lbl = Label.new()
		lbl.text = "尚无重要人生记录"
		_memories_list.add_child(lbl)
		return

	for mem in memories.slice(memories.size() - 5, memories.size()):
		var lbl = Label.new()
		lbl.text = "  " + mem
		_memories_list.add_child(lbl)


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

const TASK_COST_TYPE: Dictionary = {
	"cultivating": "",
	"alchemy": "/月",
	"crafting": "/月",
	"exploring": " 次",
	"guarding": "",
	"teaching": "",
	"idle": "",
	"market_work": "",
	"herb_gathering": "",
	"guard_caravan": "",
	"beast_hunting": "",
	"teach_wanderers": "",
}

func _populate_task_options() -> void:
	_task_option.clear()
	_task_option.add_item("闭关修炼 (免费)", 0)
	_task_option.add_item("炼丹 (10灵石/月)", 1)
	_task_option.add_item("炼器 (10灵石/月)", 2)
	_task_option.add_item("外出游历 (20灵石)", 3)
	_task_option.add_item("镇守山门 (免费)", 4)
	_task_option.add_item("教导弟子 (免费)", 5)
	_task_option.add_item("-- 打工赚灵石 --", -1)
	_task_option.set_item_disabled(6, true)
	_task_option.add_item("坊市打工 (+10~25/月)", 7)
	_task_option.add_item("采集灵草 (+15~30/月)", 8)
	_task_option.add_item("护送商队 (+30~50/月)", 9)
	_task_option.add_item("猎杀妖兽 (+25~60/月)", 10)
	_task_option.add_item("教导散修 (+20~40/月)", 11)
	_task_option.add_item("空闲", 12)


func _task_option_update() -> void:
	if not _current_disciple:
		return
	var task_map = {
		"cultivating": 0, "alchemy": 1, "crafting": 2, "exploring": 3,
		"guarding": 4, "teaching": 5,
		"market_work": 7, "herb_gathering": 8, "guard_caravan": 9,
		"beast_hunting": 10, "teach_wanderers": 11, "idle": 12,
	}
	_task_option.select(task_map.get(_current_disciple.assigned_task, 12))


func _refresh_position_selector() -> void:
	_position_option.clear()
	if not _current_disciple:
		return

	var current_pos = _current_disciple.position
	var sect = GameManager.current_sect
	if not sect:
		return

	var idx = 0
	for pos_name in DataRegistry.sect_positions:
		var pos_data = DataRegistry.sect_positions[pos_name]
		if sect.rank > pos_data.get("rank_unlock", 9):
			continue
		if _current_disciple.realm < pos_data.get("min_realm", 0) and pos_name != "普通弟子":
			continue

		var cur_count = SectController.get_position_count(pos_name)
		var max_count = SectController.get_position_max(pos_name)
		var label = "%s (%d/%d) %d灵石/月" % [pos_name, cur_count, max_count, pos_data.get("salary", 0)]
		_position_option.add_item(label)
		_position_option.set_item_metadata(_position_option.item_count - 1, pos_name)
		if pos_name == current_pos:
			_position_option.select(_position_option.item_count - 1)


func _on_position_changed(idx: int) -> void:
	if not _current_disciple:
		return
	var new_pos = _position_option.get_item_metadata(idx)
	var ok = SectController.assign_position(_current_disciple, new_pos)
	if not ok:
		_refresh_position_selector()


func _on_task_changed(idx: int) -> void:
	if not _current_disciple:
		return
	# 分隔符项，忽略
	if idx == 6:
		_task_option_update()
		return
	var task_map = {
		0: "cultivating", 1: "alchemy", 2: "crafting", 3: "exploring",
		4: "guarding", 5: "teaching",
		7: "market_work", 8: "herb_gathering", 9: "guard_caravan",
		10: "beast_hunting", 11: "teach_wanderers", 12: "idle",
	}
	var task_id = task_map.get(idx, "idle")
	var ok = DiscipleController.assign_task(_current_disciple, task_id)
	if not ok:
		_task_option_update()  # 恢复到之前的状态
