class_name GameHUD
extends Control
## 游戏主 HUD — 顶部资源栏 + 标签导航


@onready var date_label: Label = $TopBar/DateLabel
@onready var spirit_stones_label: Label = $TopBar/SpiritStonesLabel
@onready var prestige_label: Label = $TopBar/PrestigeLabel
@onready var disciple_count_label: Label = $TopBar/DiscipleCountLabel
@onready var notification_badge: Label = $TopBar/NotificationBadge
@onready var main_tab_container: TabContainer = $"../MainView/TabContainer"
@onready var advance_month_button: Button = $TopBar/AdvanceMonthButton

var _event_ledger_badge: Label
var _event_ledger_btn: Button
var _nav_buttons: Array[Button] = []
var _tab_nav: Dictionary = {}
var _top_bar_chrome: Panel
var _active_tab: int = 0


func _ready() -> void:
	EventBus.month_passed.connect(_refresh_display)
	EventBus.spirit_stones_changed.connect(_on_stones_changed)
	EventBus.sect_rank_changed.connect(_on_rank_changed)
	EventBus.disciple_recruited.connect(_on_disciple_count_changed)
	EventBus.disciple_died.connect(_on_disciple_count_changed)
	EventBus.disciple_broken_through.connect(_on_disciple_breakthrough)
	EventBus.event_ledger_changed.connect(_refresh_event_badge)
	advance_month_button.pressed.connect(_on_advance_month)
	_build_top_bar_chrome()
	_style_top_bar()
	_build_side_nav()
	_bind_tab_nav_buttons()
	if main_tab_container:
		main_tab_container.tabs_visible = false
		main_tab_container.tab_changed.connect(_on_tab_changed)

	_refresh_display(TimeManager.month, TimeManager.year)
	_refresh_event_badge()


func _build_side_nav() -> void:
	var panel = PanelContainer.new()
	panel.name = "SideNav"
	panel.position = Vector2(10, 60)
	panel.size = Vector2(165, 1010)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.055, 0.04, 0.94)
	style.border_color = Color(0.42, 0.34, 0.18, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var nav = VBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	nav.set_anchors_preset(Control.PRESET_FULL_RECT)
	nav.offset_left = 10
	nav.offset_top = 10
	nav.offset_right = -10
	nav.offset_bottom = -10
	panel.add_child(nav)

	var title = Label.new()
	title.text = "宗门"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.92, 0.82, 0.48, 1.0))
	nav.add_child(title)

	nav.add_child(_make_nav_button("掌门总览", func(): _select_tab(0)))
	nav.add_child(_make_nav_button("弟子名册", func(): _select_tab(1)))
	nav.add_child(_make_nav_button("天下地图", func(): _select_tab(2)))
	nav.add_child(HSeparator.new())

	_event_ledger_btn = _make_nav_button("宗门纪事", _on_event_ledger_pressed)
	nav.add_child(_event_ledger_btn)
	nav.add_child(_make_nav_button("天下榜", _on_diplomacy_pressed))
	nav.add_child(_make_nav_button("宗门全景", _on_sectview_pressed))
	nav.add_child(_make_nav_button("秘境探索", _on_dungeon_pressed))
	nav.add_child(_make_nav_button("炼丹炼器", _on_alchemy_pressed))
	nav.add_child(_make_nav_button("仓库", _on_warehouse_pressed))
	nav.add_child(_make_nav_button("修真史记", _on_lore_pressed))

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav.add_child(spacer)
	nav.add_child(_make_nav_button("存档", _on_save_pressed))


func _make_nav_button(text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 38)
	btn.add_theme_font_size_override("font_size", 17)
	_apply_nav_button_style(btn, false, false)
	btn.pressed.connect(callback)
	_nav_buttons.append(btn)
	return btn


func _build_top_bar_chrome() -> void:
	_top_bar_chrome = Panel.new()
	_top_bar_chrome.name = "TopBarChrome"
	_top_bar_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_bar_chrome.position = Vector2(185, 4)
	_top_bar_chrome.size = Vector2(1728, 46)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.042, 0.028, 0.94)
	style.border_color = Color(0.58, 0.45, 0.18, 0.84)
	style.border_width_bottom = 1
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	_top_bar_chrome.add_theme_stylebox_override("panel", style)
	add_child(_top_bar_chrome)
	move_child(_top_bar_chrome, 0)


func _style_top_bar() -> void:
	var labels = [date_label, spirit_stones_label, prestige_label, disciple_count_label]
	for label in labels:
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.9, 0.82, 0.48, 1.0))
		label.custom_minimum_size = Vector2(150, 30)
	_apply_nav_button_style(advance_month_button, false, false)


func _bind_tab_nav_buttons() -> void:
	if _nav_buttons.size() >= 3:
		_tab_nav[0] = _nav_buttons[0]
		_tab_nav[1] = _nav_buttons[1]
		_tab_nav[2] = _nav_buttons[2]
	_refresh_nav_styles()


func _apply_nav_button_style(btn: Button, active: bool, alert: bool) -> void:
	var normal = _make_nav_button_style(active, alert)
	var hover = _make_nav_button_style(true, alert)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", Color.WHITE if active else Color(0.9, 0.78, 0.35, 1.0))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)


func _make_nav_button_style(active: bool, alert: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.115, 0.064, 0.92)
	style.border_color = Color(0.38, 0.30, 0.14, 0.72)
	if active:
		style.bg_color = Color(0.24, 0.17, 0.08, 0.96)
		style.border_color = Color(0.9, 0.78, 0.25, 1.0)
	if alert:
		style.border_color = Color(0.95, 0.42, 0.26, 0.92)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


func _select_tab(index: int) -> void:
	if main_tab_container and index >= 0 and index < main_tab_container.get_tab_count():
		main_tab_container.current_tab = index
		_active_tab = index
		_refresh_nav_styles()


func _on_tab_changed(tab: int) -> void:
	_active_tab = tab
	_refresh_nav_styles()


func _refresh_nav_styles() -> void:
	for btn in _nav_buttons:
		var is_active = _tab_nav.has(_active_tab) and _tab_nav[_active_tab] == btn
		var is_alert = btn == _event_ledger_btn and EventController.unread_event_count > 0
		_apply_nav_button_style(btn, is_active, is_alert)


func _refresh_display(_month: int, _year: int) -> void:
	var sect = GameManager.current_sect
	if not sect:
		return

	date_label.text = TimeManager.get_date_string()
	spirit_stones_label.text = "灵石: %d" % sect.spirit_stones
	prestige_label.text = "声望: %d" % sect.prestige
	disciple_count_label.text = "弟子: %d/%d" % [sect.disciples.size(), sect.max_disciples()]


	_apply_resource_colors(sect)


func _on_stones_changed(new_amount: int, _delta: int) -> void:
	spirit_stones_label.text = "灵石: %d" % new_amount


func _apply_resource_colors(sect: Resource) -> void:
	date_label.add_theme_color_override("font_color", Color(0.9, 0.82, 0.48, 1.0))
	spirit_stones_label.add_theme_color_override("font_color", Color(0.93, 0.82, 0.38, 1.0))
	prestige_label.add_theme_color_override("font_color", Color(0.62, 0.82, 1.0, 1.0))
	var ratio = float(sect.disciples.size()) / float(maxi(1, sect.max_disciples()))
	var color = Color(0.6, 0.92, 0.62, 1.0)
	if ratio >= 1.0:
		color = Color(0.95, 0.36, 0.28, 1.0)
	elif ratio >= 0.8:
		color = Color(0.95, 0.68, 0.28, 1.0)
	disciple_count_label.add_theme_color_override("font_color", color)


func _on_rank_changed(_old: int, new_rank: int) -> void:
	var rank_name = _get_rank_name(new_rank)
	notification_badge.text = "宗门晋升: %s！" % rank_name
	notification_badge.visible = true
	await get_tree().create_timer(3.0).timeout
	notification_badge.visible = false


func _on_disciple_count_changed(_id: String) -> void:
	var sect = GameManager.current_sect
	if sect:
		disciple_count_label.text = "弟子: %d/%d" % [sect.disciples.size(), sect.max_disciples()]


func _on_save_pressed() -> void:
	get_parent().get_node("SavePanel").open_panel()


func _on_diplomacy_pressed() -> void:
	get_parent().get_node("DiplomacyPanel").open_panel()


func _on_alchemy_pressed() -> void:
	get_parent().get_node("AlchemyPanel").open_panel()


func _on_dungeon_pressed() -> void:
	get_parent().get_node("DungeonPanel").open_panel()


func _on_sectview_pressed() -> void:
	get_parent().get_node("SectViewPanel").open_panel()


func _on_warehouse_pressed() -> void:
	get_parent().get_node("WarehousePanel").open_panel()


func _on_event_ledger_pressed() -> void:
	get_parent().get_node("EventLedgerPanel").open_panel()
	_refresh_event_badge()


func _on_lore_pressed() -> void:
	get_parent().get_node("WorldLorePanel").open_panel()


func _on_advance_month() -> void:
	TimeManager.advance_month()


func _on_disciple_breakthrough(disciple_id: String, realm: int, _sub_realm: int) -> void:
	var sect = GameManager.current_sect
	if not sect:
		return
	var disciple_name = "弟子"
	for d in sect.disciples:
		if d.disciple_id == disciple_id:
			disciple_name = d.disciple_name
			break
	var realm_name = DataRegistry.get_realm_name(realm)
	notification_badge.text = "%s 突破至 %s！" % [disciple_name, realm_name]
	notification_badge.visible = true
	await get_tree().create_timer(3.0).timeout
	notification_badge.visible = false


func _get_rank_name(rank: int) -> String:
	var names = {
		9: "九品", 8: "八品", 7: "七品", 6: "六品", 5: "五品",
		4: "四品", 3: "三品", 2: "二品", 1: "一品", 0: "超品",
	}
	return names.get(rank, "未知")


func _refresh_event_badge() -> void:
	if _event_ledger_btn:
		var count = EventController.unread_event_count
		_event_ledger_btn.text = "宗门纪事" if count == 0 else "● 宗门纪事"
		_refresh_nav_styles()
