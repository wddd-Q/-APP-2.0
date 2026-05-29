class_name SectViewPanel
extends Control
## 宗门鸟瞰视图 — 显示设施布局、弟子、资源概览


const SECT_MAP_PATH := "res://assets/textures/maps/sect_map.png"

const BUILDING_COLORS: Dictionary = {
	"cultivation_chamber": Color(0.3, 0.5, 0.8, 1.0),
	"alchemy_hall": Color(0.9, 0.3, 0.2, 1.0),
	"scripture_pavilion": Color(0.7, 0.6, 0.2, 1.0),
	"arena": Color(0.7, 0.3, 0.1, 1.0),
	"formation_hall": Color(0.5, 0.2, 0.7, 1.0),
	"spirit_beast_garden": Color(0.2, 0.7, 0.3, 1.0),
	"spirit_field": Color(0.1, 0.7, 0.2, 1.0),
	"spirit_vein": Color(0.2, 0.6, 0.9, 1.0),
	"medical_hall": Color(0.9, 0.5, 0.5, 1.0),
	"guest_quarters": Color(0.6, 0.4, 0.2, 1.0),
}

const TASK_ANCHORS: Dictionary = {
	"": "__main_hall",
	"idle": "__main_hall",
	"cultivating": "cultivation_chamber",
	"alchemy": "alchemy_hall",
	"crafting": "alchemy_hall",
	"exploring": "__outside",
	"guarding": "__gate",
	"teaching": "scripture_pavilion",
	"market_work": "__outside",
	"herb_gathering": "spirit_field",
	"guard_caravan": "__outside",
	"beast_hunting": "spirit_beast_garden",
	"teach_wanderers": "guest_quarters",
}

const EFFECT_LABELS: Dictionary = {
	"cultivation_bonus": "修炼效率",
	"capacity": "闭关容纳",
	"alchemy_bonus": "炼丹成功",
	"comprehension_bonus": "参悟效率",
	"combat_bonus": "战斗训练",
	"sect_defense": "护山防御",
	"beast_training_bonus": "御兽训练",
	"herb_output": "灵草产出",
	"stone_output": "灵石产出",
	"heal_rate": "疗伤恢复",
	"life_extension": "延寿",
	"recruit_quality_bonus": "招募资质",
}

## 设施布局坐标（相对于画布中心偏移）
const LAYOUT_POSITIONS: Dictionary = {
	"spirit_vein": Vector2(0, -200),
	"cultivation_chamber": Vector2(100, -100),
	"alchemy_hall": Vector2(-120, -80),
	"scripture_pavilion": Vector2(-80, 20),
	"arena": Vector2(120, 30),
	"formation_hall": Vector2(0, -40),
	"spirit_field": Vector2(-100, 120),
	"spirit_beast_garden": Vector2(80, 140),
	"medical_hall": Vector2(0, 80),
	"guest_quarters": Vector2(150, -30),
}

var _info_label: RichTextLabel
var _canvas: Control
var _map_texture: Texture2D
var _selected_facility_type: String = ""
var _panel: Panel


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	EventBus.month_passed.connect(_on_data_changed)
	EventBus.facility_built.connect(_on_data_changed)
	EventBus.facility_upgraded.connect(_on_data_changed)
	EventBus.disciple_task_assigned.connect(_on_data_changed)
	EventBus.position_changed.connect(_on_data_changed)


func _build_ui() -> void:
	_map_texture = _load_texture(SECT_MAP_PATH)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			visible = false
	)
	add_child(bg)

	_panel = Panel.new()
	add_child(_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	vbox.add_theme_constant_override("margin_left", 14)
	vbox.add_theme_constant_override("margin_right", 14)
	vbox.add_theme_constant_override("margin_top", 10)
	vbox.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(vbox)

	# 标题栏
	var title_bar = HBoxContainer.new()
	title_bar.add_theme_constant_override("separation", 10)
	vbox.add_child(title_bar)

	var title = Label.new()
	title.text = "宗门全景"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	title_bar.add_child(title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.pressed.connect(func(): visible = false)
	title_bar.add_child(close_btn)

	# 中间：绘制区域（自定义draw） + 右侧信息
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)

	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(440, 420)
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_on_draw.bind(_canvas))
	_canvas.gui_input.connect(_on_canvas_input)
	hbox.add_child(_canvas)

	# 右侧信息
	_info_label = RichTextLabel.new()
	_info_label.custom_minimum_size = Vector2(230, 0)
	_info_label.bbcode_enabled = true
	_info_label.add_theme_font_size_override("normal_font_size", 14)
	_info_label.fit_content = false
	hbox.add_child(_info_label)

	# 底部
	var close_bottom = Button.new()
	close_bottom.text = "关闭"
	close_bottom.pressed.connect(func(): visible = false)
	vbox.add_child(close_bottom)
	_layout_panel()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _panel:
		_layout_panel()
		_refresh()


func _layout_panel() -> void:
	var vp = get_viewport().get_visible_rect().size
	var width = minf(1080.0, maxf(720.0, vp.x - 64.0))
	var height = minf(740.0, maxf(560.0, vp.y - 64.0))
	_panel.size = Vector2(width, height)
	_panel.position = Vector2(maxf(16.0, (vp.x - width) / 2.0), maxf(16.0, (vp.y - height) / 2.0))


func open_panel() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	if _info_label:
		_update_info()
	if _canvas:
		_canvas.queue_redraw()


func _update_info() -> void:
	var sect = GameManager.current_sect
	if not sect:
		return
	_info_label.clear()
	_info_label.append_text("[b]%s[/b]\n" % sect.name)
	_info_label.append_text("品级: %d品\n" % sect.rank)
	_info_label.append_text("声望: %d\n" % sect.prestige)
	_info_label.append_text("灵石: %d\n" % sect.spirit_stones)
	_info_label.append_text("宗门历: %d年%d月\n\n" % [TimeManager.year, TimeManager.month])

	_add_distribution_summary(sect)

	if _selected_facility_type != "":
		_add_selected_facility_info(sect)
	else:
		_info_label.append_text("[color=#b9ab78]点击地图上的设施，可查看驻留弟子与升级变化。[/color]\n\n")

	_info_label.append_text("[b]已建设施:[/b]\n")
	for f in sect.facilities:
		var tmpl = DataRegistry.facility_templates.get(f.facility_type, {})
		var count = _get_disciples_at_anchor(sect, f.facility_type).size()
		_info_label.append_text("  %s Lv.%d  弟子%d\n" % [tmpl.get("name", "?"), f.level, count])
	_info_label.append_text("\n设施数: %d/%d" % [sect.facilities.size(), sect.max_facilities()])
	_info_label.append_text("\n弟子数: %d/%d" % [sect.disciples.size(), sect.max_disciples()])


func _on_draw(canvas: Control) -> void:
	var sect = GameManager.current_sect
	if not sect:
		return

	var center = Vector2(canvas.size.x / 2.0, canvas.size.y / 2.0)
	var layout_scale = _get_layout_scale(canvas)

	# AI 绘制底图，设施状态仍由游戏数据叠加。
	if _map_texture:
		canvas.draw_texture_rect(_map_texture, Rect2(Vector2.ZERO, canvas.size), false)
		canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color(0, 0, 0, 0.16))
	else:
		canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color(0.15, 0.25, 0.12, 1.0))

	# 宗门中心地基
	canvas.draw_circle(center, 40, Color(0.3, 0.3, 0.3, 0.7))

	# 主殿（宗门中心）
	var main_bldg = Rect2(center - Vector2(22, 18), Vector2(44, 36))
	canvas.draw_rect(main_bldg, Color(0.85, 0.7, 0.3, 1.0))
	canvas.draw_rect(main_bldg, Color(0.6, 0.5, 0.2, 1.0), false, 2.0)
	# 主殿标签
	canvas.draw_string(ThemeDB.fallback_font,
		center + Vector2(-16, 25), "宗门大殿",
		HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE
	)

	# 绘制道路（连接各设施到中心）
	for f in sect.facilities:
		var pos_offset = LAYOUT_POSITIONS.get(f.facility_type, Vector2.ZERO)
		if pos_offset == Vector2.ZERO:
			continue
		var bldg_pos = center + pos_offset * layout_scale
		canvas.draw_line(center, bldg_pos, Color(0.4, 0.35, 0.25, 0.6), 2.0)

	# 绘制设施
	for f in sect.facilities:
		var pos_offset = LAYOUT_POSITIONS.get(f.facility_type, Vector2.ZERO)
		if pos_offset == Vector2.ZERO:
			continue
		var bldg_pos = center + pos_offset * layout_scale
		var bldg_color = BUILDING_COLORS.get(f.facility_type, Color.GRAY)
		if f.facility_type == _selected_facility_type:
			bldg_color = bldg_color.lightened(0.35)
		var tmpl = DataRegistry.facility_templates.get(f.facility_type, {})
		var size = (16.0 + f.level * 4.0) * maxf(0.86, layout_scale)  # 等级越高建筑越大

		# 建筑阴影
		canvas.draw_rect(Rect2(bldg_pos - Vector2(size, size) + Vector2(2, 2), Vector2(size * 2, size * 2)),
			Color(0, 0, 0, 0.4))

		# 建筑主体
		canvas.draw_rect(Rect2(bldg_pos - Vector2(size, size), Vector2(size * 2, size * 2)),
			bldg_color)

		# 边框
		canvas.draw_rect(Rect2(bldg_pos - Vector2(size, size), Vector2(size * 2, size * 2)),
			bldg_color.darkened(0.3), false, 2.0)

		if f.facility_type == _selected_facility_type:
			canvas.draw_circle(bldg_pos, size + 9, Color(1.0, 0.85, 0.25, 0.35), false, 3.0)

		# 等级星标
		var stars = ""
		for _i in range(f.level): stars += "★"
		canvas.draw_string(ThemeDB.fallback_font,
			bldg_pos + Vector2(-size, size + 8),
			stars,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 10,
			Color.GOLD
		)

		# 建筑名
		var name = tmpl.get("name", "?")
		canvas.draw_string(ThemeDB.fallback_font,
			bldg_pos + Vector2(-16, -size - 14),
			"%s Lv.%d" % [name, f.level],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			Color.WHITE
		)

	# 围墙
	var wall_radius = minf(canvas.size.x, canvas.size.y) * 0.43
	canvas.draw_arc(center, wall_radius, 0, TAU, 64, Color(0.5, 0.45, 0.35, 0.5), 2.0, true)

	# 山门
	var gate_pos = center + Vector2(0, -wall_radius)
	canvas.draw_rect(Rect2(gate_pos - Vector2(15, 5), Vector2(30, 10)),
		Color(0.8, 0.6, 0.2, 1.0))
	canvas.draw_string(ThemeDB.fallback_font,
		gate_pos + Vector2(-12, -10), "山门",
		HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.9, 0.85, 0.6, 1.0)
	)

	# 灵脉特效（中心光环）
	var vein = sect.get_facility("spirit_vein")
	if vein:
		var glow_alpha = 0.1 + vein.level * 0.05
		for i in range(3):
			canvas.draw_circle(center, 60.0 + i * 30,
				Color(0.3, 0.6, 1.0, glow_alpha), false, 1.5)
		canvas.draw_circle(center, 50, Color(0.3, 0.7, 1.0, glow_alpha * 2))

	_draw_disciple_markers(canvas, sect, center, wall_radius, layout_scale)
	_draw_legend(canvas)


func _on_canvas_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_selected_facility_type = _find_facility_at(ev.position)
		_refresh()


func _find_facility_at(pos: Vector2) -> String:
	var sect = GameManager.current_sect
	if not sect or not _canvas:
		return ""
	var center = Vector2(_canvas.size.x / 2.0, _canvas.size.y / 2.0)
	var layout_scale = _get_layout_scale(_canvas)
	for f in sect.facilities:
		var pos_offset = LAYOUT_POSITIONS.get(f.facility_type, Vector2.ZERO)
		if pos_offset == Vector2.ZERO:
			continue
		var bldg_pos = center + pos_offset * layout_scale
		var hit_radius = (24.0 + f.level * 4.0) * maxf(0.86, layout_scale)
		if pos.distance_to(bldg_pos) <= hit_radius:
			return f.facility_type
	return ""


func _add_selected_facility_info(sect: Resource) -> void:
	var facility = sect.get_facility(_selected_facility_type)
	if not facility:
		return
	var tmpl = DataRegistry.facility_templates.get(_selected_facility_type, {})
	_info_label.append_text("[b]当前选中:[/b]\n")
	_info_label.append_text("%s Lv.%d\n" % [tmpl.get("name", _selected_facility_type), facility.level])
	var effect_text = _get_facility_effect_summary(tmpl, facility.level)
	if not effect_text.is_empty():
		_info_label.append_text(effect_text + "\n")
	var maintenance = tmpl.get("maintenance", {}).get(facility.level, 0)
	if maintenance > 0:
		_info_label.append_text("维护: %d灵石/月\n" % maintenance)
	_add_next_upgrade_info(tmpl, facility)
	_add_anchor_disciple_info(sect, _selected_facility_type)
	_info_label.append_text("\n")


func _add_distribution_summary(sect: Resource) -> void:
	var outside = _get_disciples_at_anchor(sect, "__outside").size()
	var gate = _get_disciples_at_anchor(sect, "__gate").size()
	var hall = _get_disciples_at_anchor(sect, "__main_hall").size()
	var in_facility = 0
	for f in sect.facilities:
		in_facility += _get_disciples_at_anchor(sect, f.facility_type).size()
	_info_label.append_text("[b]弟子分布:[/b]\n")
	_info_label.append_text("  设施内 %d  山门 %d  外派 %d  大殿 %d\n\n" % [in_facility, gate, outside, hall])


func _add_anchor_disciple_info(sect: Resource, anchor: String) -> void:
	var disciples = _get_disciples_at_anchor(sect, anchor)
	_info_label.append_text("驻留弟子: %d\n" % disciples.size())
	if disciples.is_empty():
		return
	for d in disciples.slice(0, 6):
		_info_label.append_text("  %s｜%s｜%s\n" % [d.disciple_name, d.position, _get_task_display(d.assigned_task)])
	if disciples.size() > 6:
		_info_label.append_text("  另有%d人\n" % (disciples.size() - 6))


func _add_next_upgrade_info(tmpl: Dictionary, facility: Resource) -> void:
	var max_level = tmpl.get("max_level", facility.level)
	if facility.level >= max_level:
		_info_label.append_text("升级: 已达最高等级\n")
		return
	var next_level = facility.level + 1
	var cost = tmpl.get("build_cost", {}).get(next_level, 0)
	_info_label.append_text("升级: Lv.%d 需要%d灵石\n" % [next_level, cost])
	var next_effect = _get_facility_effect_summary(tmpl, next_level)
	if not next_effect.is_empty():
		_info_label.append_text("下级: %s\n" % next_effect)


func _get_facility_effect_summary(tmpl: Dictionary, level: int) -> String:
	var parts: Array[String] = []
	for key in EFFECT_LABELS:
		if not tmpl.has(key):
			continue
		var level_map = tmpl.get(key, {})
		if typeof(level_map) != TYPE_DICTIONARY:
			continue
		if not level_map.has(level):
			continue
		parts.append(_format_effect_value(key, level_map[level]))
	return "，".join(parts)


func _format_effect_value(effect_key: String, value) -> String:
	var label = EFFECT_LABELS.get(effect_key, effect_key)
	if effect_key in ["cultivation_bonus", "alchemy_bonus", "comprehension_bonus", "combat_bonus", "sect_defense", "beast_training_bonus", "heal_rate"]:
		return "%s +%d%%" % [label, int(round(float(value) * 100.0))]
	if effect_key == "capacity":
		return "%s %d人" % [label, int(value)]
	if effect_key in ["herb_output", "stone_output"]:
		return "%s +%d/月" % [label, int(value)]
	if effect_key == "life_extension":
		return "%s +%d年" % [label, int(value)]
	if effect_key == "recruit_quality_bonus":
		return "%s +%d" % [label, int(value)]
	return "%s %s" % [label, str(value)]


func _draw_disciple_markers(canvas: Control, sect: Resource, center: Vector2, wall_radius: float, layout_scale: float) -> void:
	var groups = _get_disciple_anchor_groups(sect)
	for anchor in groups:
		var disciples: Array = groups[anchor]
		var anchor_pos = _get_anchor_position(anchor, center, wall_radius, layout_scale)
		var max_visible = mini(disciples.size(), 8)
		for i in range(max_visible):
			var d = disciples[i]
			var angle = TAU * float(i) / float(maxi(1, max_visible))
			var offset_radius = 22.0 if max_visible > 1 else 0.0
			var marker_pos = anchor_pos + Vector2(cos(angle), sin(angle)) * offset_radius
			var color = _get_disciple_marker_color(d)
			canvas.draw_circle(marker_pos + Vector2(1, 1), 7.0, Color(0, 0, 0, 0.55))
			canvas.draw_circle(marker_pos, 6.5, color)
			canvas.draw_circle(marker_pos, 6.5, Color(0.08, 0.06, 0.03, 0.9), false, 1.2)
			canvas.draw_string(ThemeDB.fallback_font,
				marker_pos + Vector2(-4, 4), d.disciple_name.left(1),
				HORIZONTAL_ALIGNMENT_CENTER, 10, 10, Color(0.08, 0.06, 0.03, 1.0)
			)
		if disciples.size() > max_visible:
			canvas.draw_string(ThemeDB.fallback_font,
				anchor_pos + Vector2(16, 18), "+%d" % (disciples.size() - max_visible),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.93, 0.68, 1.0)
			)


func _draw_legend(canvas: Control) -> void:
	var base = Vector2(14, canvas.size.y - 62)
	canvas.draw_rect(Rect2(base - Vector2(8, 16), Vector2(178, 54)), Color(0.05, 0.04, 0.03, 0.48))
	canvas.draw_string(ThemeDB.fallback_font, base, "弟子位置", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.86, 0.62, 1.0))
	canvas.draw_circle(base + Vector2(8, 18), 5.5, Color(0.95, 0.78, 0.32, 1.0))
	canvas.draw_string(ThemeDB.fallback_font, base + Vector2(20, 22), "任职弟子", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	canvas.draw_circle(base + Vector2(86, 18), 5.5, Color(0.55, 0.86, 0.96, 1.0))
	canvas.draw_string(ThemeDB.fallback_font, base + Vector2(98, 22), "普通弟子", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)


func _get_disciple_anchor_groups(sect: Resource) -> Dictionary:
	var groups: Dictionary = {}
	for d in sect.disciples:
		if not d.alive:
			continue
		var anchor = _get_disciple_anchor(sect, d)
		if not groups.has(anchor):
			groups[anchor] = []
		groups[anchor].append(d)
	return groups


func _get_disciples_at_anchor(sect: Resource, anchor: String) -> Array:
	var result: Array = []
	for d in sect.disciples:
		if d.alive and _get_disciple_anchor(sect, d) == anchor:
			result.append(d)
	return result


func _get_disciple_anchor(sect: Resource, disciple: Resource) -> String:
	if disciple.location in ["exploring", "mission"] or disciple.assigned_task == "exploring":
		return "__outside"
	var anchor: String = TASK_ANCHORS.get(disciple.assigned_task, "__main_hall")
	if anchor.begins_with("__"):
		return anchor
	if sect.get_facility(anchor):
		return anchor
	return "__main_hall"


func _get_anchor_position(anchor: String, center: Vector2, wall_radius: float, layout_scale: float) -> Vector2:
	if anchor == "__main_hall":
		return center
	if anchor == "__gate":
		return center + Vector2(0, -wall_radius + 14)
	if anchor == "__outside":
		return center + Vector2(0, -wall_radius - 22)
	return center + LAYOUT_POSITIONS.get(anchor, Vector2.ZERO) * layout_scale


func _get_layout_scale(canvas: Control) -> float:
	return clampf(minf(canvas.size.x / 560.0, canvas.size.y / 470.0), 0.78, 1.15)


func _get_disciple_marker_color(disciple: Resource) -> Color:
	if disciple.position != "普通弟子":
		return Color(0.95, 0.78, 0.32, 1.0)
	if disciple.assigned_task in ["market_work", "guard_caravan", "beast_hunting", "exploring"]:
		return Color(0.78, 0.84, 0.90, 1.0)
	return Color(0.55, 0.86, 0.96, 1.0)


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


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img = Image.new()
	var err = img.load(ProjectSettings.globalize_path(path))
	if err == OK:
		return ImageTexture.create_from_image(img)
	return null


func _on_data_changed(_a = null, _b = null, _c = null) -> void:
	if visible:
		_refresh()
