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


func _ready() -> void:
	EventBus.month_passed.connect(_refresh_display)
	EventBus.spirit_stones_changed.connect(_on_stones_changed)
	EventBus.sect_rank_changed.connect(_on_rank_changed)
	EventBus.disciple_recruited.connect(_on_disciple_count_changed)
	EventBus.disciple_died.connect(_on_disciple_count_changed)
	EventBus.disciple_broken_through.connect(_on_disciple_breakthrough)
	EventBus.event_ledger_changed.connect(_refresh_event_badge)
	advance_month_button.pressed.connect(_on_advance_month)

	# 存档按钮
	var save_btn = Button.new()
	save_btn.text = "存档"
	save_btn.add_theme_font_size_override("font_size", 18)
	save_btn.pressed.connect(_on_save_pressed)
	$TopBar.add_child(save_btn)
	$TopBar.move_child(save_btn, $TopBar.get_child_count() - 2)

	# 外交按钮
	var diplo_btn = Button.new()
	diplo_btn.text = "天下榜"
	diplo_btn.add_theme_font_size_override("font_size", 18)
	diplo_btn.pressed.connect(_on_diplomacy_pressed)
	$TopBar.add_child(diplo_btn)
	$TopBar.move_child(diplo_btn, $TopBar.get_child_count() - 2)

	# 炼丹炼器按钮
	var alchemy_btn = Button.new()
	alchemy_btn.text = "炼丹炼器"
	alchemy_btn.add_theme_font_size_override("font_size", 18)
	alchemy_btn.pressed.connect(_on_alchemy_pressed)
	$TopBar.add_child(alchemy_btn)
	$TopBar.move_child(alchemy_btn, $TopBar.get_child_count() - 2)

	# 秘境探索按钮
	var dungeon_btn = Button.new()
	dungeon_btn.text = "秘境探索"
	dungeon_btn.add_theme_font_size_override("font_size", 18)
	dungeon_btn.pressed.connect(_on_dungeon_pressed)
	$TopBar.add_child(dungeon_btn)
	$TopBar.move_child(dungeon_btn, $TopBar.get_child_count() - 2)

	# 宗门全景按钮
	var sectview_btn = Button.new()
	sectview_btn.text = "宗门全景"
	sectview_btn.add_theme_font_size_override("font_size", 18)
	sectview_btn.pressed.connect(_on_sectview_pressed)
	$TopBar.add_child(sectview_btn)
	$TopBar.move_child(sectview_btn, $TopBar.get_child_count() - 2)

	# 仓库按钮
	var warehouse_btn = Button.new()
	warehouse_btn.text = "仓库"
	warehouse_btn.add_theme_font_size_override("font_size", 18)
	warehouse_btn.pressed.connect(_on_warehouse_pressed)
	$TopBar.add_child(warehouse_btn)
	$TopBar.move_child(warehouse_btn, $TopBar.get_child_count() - 2)

	# 宗门纪事按钮
	var ledger_btn = Button.new()
	ledger_btn.text = "宗门纪事"
	ledger_btn.add_theme_font_size_override("font_size", 18)
	ledger_btn.pressed.connect(_on_event_ledger_pressed)
	$TopBar.add_child(ledger_btn)
	$TopBar.move_child(ledger_btn, $TopBar.get_child_count() - 2)

	_event_ledger_badge = Label.new()
	_event_ledger_badge.text = "●"
	_event_ledger_badge.visible = false
	_event_ledger_badge.add_theme_font_size_override("font_size", 18)
	_event_ledger_badge.add_theme_color_override("font_color", Color(1.0, 0.12, 0.08, 1.0))
	$TopBar.add_child(_event_ledger_badge)
	$TopBar.move_child(_event_ledger_badge, $TopBar.get_child_count() - 2)

	# 修真史记按钮
	var lore_btn = Button.new()
	lore_btn.text = "修真史记"
	lore_btn.add_theme_font_size_override("font_size", 18)
	lore_btn.pressed.connect(_on_lore_pressed)
	$TopBar.add_child(lore_btn)
	$TopBar.move_child(lore_btn, $TopBar.get_child_count() - 2)

	_refresh_display(TimeManager.month, TimeManager.year)
	_refresh_event_badge()


func _refresh_display(_month: int, _year: int) -> void:
	var sect = GameManager.current_sect
	if not sect:
		return

	date_label.text = TimeManager.get_date_string()
	spirit_stones_label.text = "灵石: %d" % sect.spirit_stones
	prestige_label.text = "声望: %d" % sect.prestige
	disciple_count_label.text = "弟子: %d/%d" % [sect.disciples.size(), sect.max_disciples()]


func _on_stones_changed(new_amount: int, _delta: int) -> void:
	spirit_stones_label.text = "灵石: %d" % new_amount


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
	if not _event_ledger_badge:
		return
	_event_ledger_badge.visible = EventController.unread_event_count > 0
