class_name DungeonPanel
extends Control
## 秘境探索面板


var _dungeon_list: VBoxContainer
var _detail_label: RichTextLabel
var _disciple_selectors: Array = []
var _ally_selector: OptionButton
var _status_label: Label
var _selected_dungeon_id: String = ""


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	EventBus.dungeon_expedition_started.connect(func(_id, _ids): _refresh())
	EventBus.dungeon_expedition_finished.connect(func(_id, _success, _loot): _refresh())
	EventBus.dungeon_discovered.connect(func(_id): _refresh())


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
	panel.size = Vector2(760, 580)
	panel.position = Vector2(get_viewport().get_visible_rect().size / 2 - panel.size / 2)
	add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	# 左侧：副本列表
	var left = VBoxContainer.new()
	left.custom_minimum_size = Vector2(240, 0)
	left.add_theme_constant_override("separation", 8)
	hbox.add_child(left)

	var title = Label.new()
	title.text = "秘境探索"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	left.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)

	_dungeon_list = VBoxContainer.new()
	_dungeon_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_dungeon_list)

	# 右侧：详情 + 操作
	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(460, 0)
	right.add_theme_constant_override("separation", 10)
	hbox.add_child(right)

	_detail_label = RichTextLabel.new()
	_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_label.bbcode_enabled = true
	_detail_label.add_theme_font_size_override("normal_font_size", 15)
	right.add_child(_detail_label)

	# 弟子选择区
	var disciple_label = Label.new()
	disciple_label.text = "派遣弟子:"
	disciple_label.add_theme_font_size_override("font_size", 16)
	right.add_child(disciple_label)

	var disciple_row = HBoxContainer.new()
	disciple_row.add_theme_constant_override("separation", 8)
	right.add_child(disciple_row)
	for _i in range(5):
		var sel = OptionButton.new()
		sel.add_theme_font_size_override("font_size", 14)
		sel.visible = false
		disciple_row.add_child(sel)
		_disciple_selectors.append(sel)

	# 盟友选择
	var ally_row = HBoxContainer.new()
	ally_row.add_theme_constant_override("separation", 8)
	right.add_child(ally_row)

	var ally_label = Label.new()
	ally_label.text = "同盟协助:"
	ally_label.add_theme_font_size_override("font_size", 16)
	ally_row.add_child(ally_label)

	_ally_selector = OptionButton.new()
	_ally_selector.add_theme_font_size_override("font_size", 14)
	ally_row.add_child(_ally_selector)

	# 派遣按钮
	var dispatch_btn = Button.new()
	dispatch_btn.text = "派遣探索"
	dispatch_btn.add_theme_font_size_override("font_size", 18)
	dispatch_btn.pressed.connect(_on_dispatch)
	right.add_child(dispatch_btn)

	# 状态
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	right.add_child(_status_label)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(func(): visible = false)
	right.add_child(close_btn)


func open_panel() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	_refresh_dungeon_list()
	_refresh_detail()
	_refresh_status()


func _refresh_dungeon_list() -> void:
	for child in _dungeon_list.get_children():
		child.queue_free()

	var dungeons = DungeonController.dungeon_instances
	if dungeons.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无已知秘境"
		_dungeon_list.add_child(lbl)
		return

	for dungeon_id in dungeons:
		var d: DungeonData = dungeons[dungeon_id]
		if not d.is_discovered:
			continue

		var btn = Button.new()
		var status = "就绪" if d.is_available() else ("冷却中(%d月)" % d.on_cooldown if d.on_cooldown > 0 else "探索中")
		btn.text = "%s [%s]" % [d.dungeon_name, status]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 15)
		if not d.is_available():
			btn.modulate = Color.GRAY
		var did = dungeon_id
		btn.pressed.connect(func(): _select_dungeon(did))
		_dungeon_list.add_child(btn)


func _select_dungeon(dungeon_id: String) -> void:
	_selected_dungeon_id = dungeon_id
	_refresh_detail()


func _refresh_detail() -> void:
	_detail_label.clear()
	_disciple_selectors[0].visible = false
	_disciple_selectors[1].visible = false
	_disciple_selectors[2].visible = false
	_disciple_selectors[3].visible = false
	_disciple_selectors[4].visible = false

	if _selected_dungeon_id == "":
		_detail_label.append_text("选择一个秘境以查看详情")
		return

	var d: DungeonData = DungeonController.dungeon_instances.get(_selected_dungeon_id)
	if not d:
		return

	var type_names = {"secret_realm": "秘境", "ancient_ruin": "遗迹", "beast_lair": "兽穴", "demon_cave": "魔窟", "mine": "矿洞"}
	var stars = ""
	for _i in range(d.difficulty): stars += "★"
	for _i in range(10 - d.difficulty): stars += "☆"

	_detail_label.append_text("[b]%s[/b] [%s]\n" % [d.dungeon_name, type_names.get(d.dungeon_type, "未知")])
	_detail_label.append_text("难度: %s\n" % stars)
	_detail_label.append_text("危险: %d%%\n" % d.danger_level)
	_detail_label.append_text("耗时: %d个月\n" % d.exploration_months)
	_detail_label.append_text("需弟子: %d-%d人 (≥%s)\n\n" % [
		d.min_disciple_count, d.max_disciple_count,
		DataRegistry.get_realm_name(d.min_disciple_realm),
	])
	_detail_label.append_text("%s\n" % d.description)

	# 弟子选择器
	var sect = GameManager.current_sect
	if sect:
		var idx = 0
		for i in range(_disciple_selectors.size()):
			if i >= d.max_disciple_count:
				break
			var sel = _disciple_selectors[i]
			sel.clear()
			sel.add_item("— 选择弟子 —")
			sel.visible = true

		for disc in sect.disciples:
			if not disc.alive:
				continue
			if disc.assigned_task != "idle" and disc.assigned_task != "":
				continue
			for i in range(d.max_disciple_count):
				var sel = _disciple_selectors[i]
				sel.add_item("%s (%s 第%d层)" % [
					disc.disciple_name,
					DataRegistry.get_realm_name(disc.realm),
					disc.sub_realm,
				])
				sel.set_item_metadata(sel.item_count - 1, disc.disciple_id)

	# 盟友选择器
	_ally_selector.clear()
	_ally_selector.add_item("无")
	var allies = DungeonController.get_allied_factions()
	for ally in allies:
		_ally_selector.add_item("%s (关系:%d)" % [ally.faction_name, ally.relation_to_player])
		_ally_selector.set_item_metadata(_ally_selector.item_count - 1, ally.faction_name)


func _on_dispatch() -> void:
	if _selected_dungeon_id == "":
		_status_label.text = "请先选择一个秘境"
		return

	var d: DungeonData = DungeonController.dungeon_instances.get(_selected_dungeon_id)
	if not d:
		return

	var selected_ids: Array = []
	for sel in _disciple_selectors:
		if sel.visible and sel.selected > 0:
			var disc_id = sel.get_item_metadata(sel.selected)
			if not selected_ids.has(disc_id):
				selected_ids.append(disc_id)

	if selected_ids.size() < d.min_disciple_count:
		_status_label.text = "至少需要选择 %d 名弟子" % d.min_disciple_count
		return

	var ally = ""
	if _ally_selector.selected > 0:
		ally = _ally_selector.get_item_metadata(_ally_selector.selected)

	var result = DungeonController.dispatch_expedition(_selected_dungeon_id, selected_ids, ally)
	if result["success"]:
		_status_label.text = result["message"]
		await get_tree().create_timer(2.0).timeout
		_refresh()
	else:
		_status_label.text = result["error"]


func _refresh_status() -> void:
	var text = DungeonController.get_active_expedition_text()
	if text != "暂无进行中的探索":
		_status_label.text = "[进行中]\n" + text
