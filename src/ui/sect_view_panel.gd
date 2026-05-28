class_name SectViewPanel
extends Control
## 宗门鸟瞰视图 — 显示设施布局、弟子、资源概览


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


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	EventBus.month_passed.connect(_on_data_changed)
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
	panel.size = Vector2(760, 600)
	panel.position = Vector2(get_viewport().get_visible_rect().size / 2 - panel.size / 2)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

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

	var canvas = Control.new()
	canvas.custom_minimum_size = Vector2(520, 480)
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.draw.connect(_on_draw.bind(canvas))
	hbox.add_child(canvas)

	# 右侧信息
	_info_label = RichTextLabel.new()
	_info_label.custom_minimum_size = Vector2(200, 0)
	_info_label.bbcode_enabled = true
	_info_label.add_theme_font_size_override("normal_font_size", 14)
	hbox.add_child(_info_label)

	# 底部
	var close_bottom = Button.new()
	close_bottom.text = "关闭"
	close_bottom.pressed.connect(func(): visible = false)
	vbox.add_child(close_bottom)


func open_panel() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	if _info_label:
		_update_info()


func _update_info() -> void:
	var sect = GameManager.current_sect
	if not sect:
		return
	_info_label.clear()
	_info_label.append_text("[b]%s[/b]\n" % sect.name)
	_info_label.append_text("品级: %d品\n" % sect.rank)
	_info_label.append_text("声望: %d\n" % sect.prestige)
	_info_label.append_text("灵石: %d\n\n" % sect.spirit_stones)
	_info_label.append_text("[b]已建设施:[/b]\n")
	for f in sect.facilities:
		var tmpl = DataRegistry.facility_templates.get(f.facility_type, {})
		_info_label.append_text("  %s Lv.%d\n" % [tmpl.get("name", "?"), f.level])
	_info_label.append_text("\n设施数: %d/%d" % [sect.facilities.size(), sect.max_facilities()])
	_info_label.append_text("\n弟子数: %d/%d" % [sect.disciples.size(), sect.max_disciples()])


func _on_draw(canvas: Control) -> void:
	var sect = GameManager.current_sect
	if not sect:
		return

	var center = Vector2(canvas.size.x / 2.0, canvas.size.y / 2.0)

	# 绘制地面
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
		var bldg_pos = center + pos_offset
		canvas.draw_line(center, bldg_pos, Color(0.4, 0.35, 0.25, 0.6), 2.0)

	# 绘制设施
	for f in sect.facilities:
		var pos_offset = LAYOUT_POSITIONS.get(f.facility_type, Vector2.ZERO)
		if pos_offset == Vector2.ZERO:
			continue
		var bldg_pos = center + pos_offset
		var bldg_color = BUILDING_COLORS.get(f.facility_type, Color.GRAY)
		var tmpl = DataRegistry.facility_templates.get(f.facility_type, {})
		var size = 16.0 + f.level * 4.0  # 等级越高建筑越大

		# 建筑阴影
		canvas.draw_rect(Rect2(bldg_pos - Vector2(size, size) + Vector2(2, 2), Vector2(size * 2, size * 2)),
			Color(0, 0, 0, 0.4))

		# 建筑主体
		canvas.draw_rect(Rect2(bldg_pos - Vector2(size, size), Vector2(size * 2, size * 2)),
			bldg_color)

		# 边框
		canvas.draw_rect(Rect2(bldg_pos - Vector2(size, size), Vector2(size * 2, size * 2)),
			bldg_color.darkened(0.3), false, 2.0)

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
	var wall_radius = 245.0
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


func _on_data_changed(_a = null, _b = null, _c = null) -> void:
	if visible:
		_refresh()
