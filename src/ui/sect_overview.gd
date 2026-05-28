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

		disciples_container.add_child(row)


func _refresh_resources(sect: Resource) -> void:
	for child in resources_container.get_children():
		child.queue_free()

	var main = Label.new()
	main.text = "灵石: %d" % sect.spirit_stones
	resources_container.add_child(main)

	if not sect.herbs.is_empty():
		var herbs_label = Label.new()
		herbs_label.text = "灵草: " + str(sect.herbs)
		resources_container.add_child(herbs_label)

	if not sect.ores.is_empty():
		var ores_label = Label.new()
		ores_label.text = "矿石: " + str(sect.ores)
		resources_container.add_child(ores_label)


func _refresh_decrees(sect: Resource) -> void:
	if sect.active_decrees.is_empty():
		active_decrees_label.text = "当前门规: 无"
	else:
		active_decrees_label.text = "当前门规: " + ", ".join(sect.active_decrees)


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
