class_name WarehousePanel
extends Control
## 仓库面板 — 查看所有资源库存


var _category_btns: Array = []
var _list_container: VBoxContainer
var _detail_label: RichTextLabel
var _current_category: String = "all"


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	EventBus.month_passed.connect(_on_data_changed)
	EventBus.spirit_stones_changed.connect(_on_data_changed)
	EventBus.dungeon_expedition_finished.connect(_on_loot_received)
	EventBus.facility_built.connect(_on_data_changed)
	EventBus.facility_upgraded.connect(_on_data_changed)


func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			visible = false
	)
	add_child(bg)

	var panel = Panel.new()
	panel.size = Vector2(720, 560)
	panel.position = Vector2(get_viewport().get_visible_rect().size / 2 - panel.size / 2)
	add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	# 左侧：分类按钮
	var left = VBoxContainer.new()
	left.custom_minimum_size = Vector2(160, 0)
	left.add_theme_constant_override("separation", 6)
	hbox.add_child(left)

	var title = Label.new()
	title.text = "宗门仓库"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	left.add_child(title)

	var categories = [
		["all", "全部资源"],
		["herbs", "灵草"],
		["ores", "矿石"],
		["beast", "兽材"],
		["rare", "稀有材料"],
		["equipment", "装备/物品"],
		["recipes", "配方"],
	]
	for cat in categories:
		var btn = Button.new()
		btn.text = cat[1]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 16)
		var cat_id = cat[0]
		btn.pressed.connect(func(): _switch_category(cat_id))
		_category_btns.append(btn)
		left.add_child(btn)

	# 右侧：列表 + 详情
	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(520, 0)
	right.add_theme_constant_override("separation", 10)
	hbox.add_child(right)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)

	_list_container = VBoxContainer.new()
	_list_container.add_theme_constant_override("separation", 6)
	scroll.add_child(_list_container)

	_detail_label = RichTextLabel.new()
	_detail_label.bbcode_enabled = true
	_detail_label.add_theme_font_size_override("normal_font_size", 15)
	_detail_label.custom_minimum_size = Vector2(0, 80)
	right.add_child(_detail_label)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(func(): visible = false)
	right.add_child(close_btn)


func open_panel() -> void:
	visible = true
	_switch_category("all")


func _switch_category(cat: String) -> void:
	_current_category = cat
	_refresh()


func _refresh() -> void:
	for child in _list_container.get_children():
		child.queue_free()

	var sect = GameManager.current_sect
	if not sect:
		var lbl = Label.new()
		lbl.text = "宗门数据未加载"
		_list_container.add_child(lbl)
		return

	match _current_category:
		"all": _show_all(sect)
		"herbs": _show_herbs(sect)
		"ores": _show_ores(sect)
		"beast": _show_beast_materials(sect)
		"rare": _show_rare_materials(sect)
		"equipment": _show_equipment(sect)
		"recipes": _show_recipes(sect)


func _show_all(sect: Resource) -> void:
	_show_section("灵石", {"灵石": sect.spirit_stones}, "灵石")
	_show_section("灵草", sect.herbs, "株")
	_show_section("矿石", sect.ores, "块")
	_show_section("兽材", sect.beast_materials, "份")
	_show_section("稀有材料", sect.rare_materials, "份")
	_show_section("配方 — 丹药", _count_dict(sect.pill_recipes), "个")
	_show_section("配方 — 炼器", _count_dict(sect.craft_recipes), "个")
	_show_inventory_section(sect)


func _show_herbs(sect: Resource) -> void:
	_show_section("灵草", sect.herbs, "株")


func _show_ores(sect: Resource) -> void:
	_show_section("矿石", sect.ores, "块")


func _show_beast_materials(sect: Resource) -> void:
	_show_section("兽材", sect.beast_materials, "份")


func _show_rare_materials(sect: Resource) -> void:
	_show_section("稀有材料", sect.rare_materials, "份")


func _show_equipment(sect: Resource) -> void:
	_show_inventory_section(sect)


func _show_recipes(sect: Resource) -> void:
	_show_section("丹药配方", _count_dict(sect.pill_recipes), "个")
	_show_section("炼器配方", _count_dict(sect.craft_recipes), "个")


func _show_section(label_name: String, data, unit: String) -> void:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var header = Label.new()
	header.text = "■ %s" % label_name
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	section.add_child(header)

	if data is Dictionary and data.is_empty():
		var empty = Label.new()
		empty.text = "  （空）"
		empty.add_theme_color_override("font_color", Color.GRAY)
		section.add_child(empty)
	elif data is Dictionary:
		for key in data:
			var val = data[key]
			var item_name = _get_display_name(key)
			var row = Label.new()
			row.text = "  %s: %d %s" % [item_name, val, unit]
			row.add_theme_font_size_override("font_size", 15)
			section.add_child(row)
	elif data is int:
		var row = Label.new()
		row.text = "  %d %s" % [data, unit]
		row.add_theme_font_size_override("font_size", 15)
		section.add_child(row)

	_list_container.add_child(section)
	_list_container.add_child(HSeparator.new())


func _get_display_name(raw_id: String) -> String:
	var name_map = {
		"spirit_herb": "灵草", "ginseng": "人参", "lingzhi": "灵芝",
		"iron": "铁矿石", "silk": "灵蚕丝", "jade": "灵玉",
		"beast_fur": "兽皮", "beast_bone": "兽骨", "beast_blood": "兽血",
		"spirit_crystal": "灵石结晶", "phoenix_feather": "凤凰翎羽",
	}
	return name_map.get(raw_id, raw_id)


func _show_inventory_section(sect: Resource) -> void:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var header = Label.new()
	header.text = "■ 装备/物品"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	section.add_child(header)

	if sect.inventory.is_empty():
		var empty = Label.new()
		empty.text = "  （空）"
		empty.add_theme_color_override("font_color", Color.GRAY)
		section.add_child(empty)
	else:
		for item in sect.inventory:
			var row = Label.new()
			if item is Resource:
				row.text = "  %s%s x%d" % [
					_get_quality_prefix(item.quality),
					item.item_name if item.item_name != "" else item.item_id,
					item.quantity,
				]
			else:
				row.text = "  %s" % str(item)
			row.add_theme_font_size_override("font_size", 15)
			section.add_child(row)

	_list_container.add_child(section)
	_list_container.add_child(HSeparator.new())


func _count_dict(d: Array) -> Dictionary:
	var result: Dictionary = {}
	for item in d:
		var name: String = ""
		if item is Dictionary:
			name = item.get("name", str(item))
		elif item is Resource:
			name = item.item_name if item.item_name != "" else item.item_id
		else:
			name = str(item)
		if name != "":
			result[name] = result.get(name, 0) + 1
	return result


func _get_quality_prefix(quality: int) -> String:
	match quality:
		4: return "极品 "
		3: return "上品 "
		2: return "中品 "
		1: return "下品 "
		0: return "废品 "
	return ""


func _on_data_changed(_a = null, _b = null, _c = null) -> void:
	if visible:
		_refresh()


func _on_loot_received(_dungeon_id: String, _success: bool, _loot: Dictionary) -> void:
	if visible:
		_refresh()
