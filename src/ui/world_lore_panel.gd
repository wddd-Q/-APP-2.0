class_name WorldLorePanel
extends Control
## 修真史记面板


var _category_list: VBoxContainer
var _content_label: RichTextLabel
var _title_label: Label
var _current_entry_id: String = ""
var _entries_by_category: Dictionary = {}
var _unlocked_entries: Array[String] = []


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_init_unlocks()
	_build_ui()
	EventBus.lore_unlocked.connect(_on_lore_unlock)
	EventBus.game_started.connect(_init_unlocks)


func _init_unlocks() -> void:
	_unlocked_entries.clear()
	for entry_id in DataRegistry.world_lore:
		var entry = DataRegistry.world_lore[entry_id]
		if entry.get("unlock_condition", "") == "default":
			_unlocked_entries.append(entry_id)


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
	panel.size = Vector2(780, 600)
	panel.position = Vector2(get_viewport().get_visible_rect().size / 2 - panel.size / 2)
	add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	# 左侧：分类目录
	var left = VBoxContainer.new()
	left.custom_minimum_size = Vector2(200, 0)
	left.add_theme_constant_override("separation", 6)
	hbox.add_child(left)

	var cat_title = Label.new()
	cat_title.text = "修真史记"
	cat_title.add_theme_font_size_override("font_size", 22)
	cat_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	left.add_child(cat_title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)

	_category_list = VBoxContainer.new()
	_category_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_category_list)

	# 右侧：内容
	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(520, 0)
	right.add_theme_constant_override("separation", 10)
	hbox.add_child(right)

	_title_label = Label.new()
	_title_label.text = "选择一篇文章阅读"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	right.add_child(_title_label)

	_content_label = RichTextLabel.new()
	_content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_label.bbcode_enabled = true
	_content_label.add_theme_font_size_override("normal_font_size", 17)
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	right.add_child(_content_label)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(func(): visible = false)
	right.add_child(close_btn)


func open_panel() -> void:
	visible = true
	_refresh_categories()


func _refresh_categories() -> void:
	for child in _category_list.get_children():
		child.queue_free()

	_entries_by_category.clear()
	for entry_id in DataRegistry.world_lore:
		var entry = DataRegistry.world_lore[entry_id]
		var cat = entry.get("category", "其他")
		if not _entries_by_category.has(cat):
			_entries_by_category[cat] = []
		_entries_by_category[cat].append({"id": entry_id, "entry": entry})

	for category in _entries_by_category:
		var cat_btn = Button.new()
		cat_btn.text = "▸ " + category
		cat_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		cat_btn.flat = true
		cat_btn.add_theme_font_size_override("font_size", 18)
		cat_btn.add_theme_color_override("font_color", Color(0.8, 0.75, 0.5, 1.0))
		_category_list.add_child(cat_btn)

		for item in _entries_by_category[category]:
			var unlocked = item["id"] in _unlocked_entries
			var entry_btn = Button.new()
			if unlocked:
				entry_btn.text = "    %s" % item["entry"]["title"]
			else:
				entry_btn.text = "    ???"
				entry_btn.modulate = Color.GRAY
			entry_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			entry_btn.flat = true
			entry_btn.add_theme_font_size_override("font_size", 15)
			if unlocked:
				var eid = item["id"]
				entry_btn.pressed.connect(func(): _show_entry(eid))
			_category_list.add_child(entry_btn)


func _show_entry(entry_id: String) -> void:
	_current_entry_id = entry_id
	var entry = DataRegistry.world_lore.get(entry_id, {})
	if entry.is_empty():
		return

	_title_label.text = entry.get("title", "")
	_content_label.clear()

	var era_names = {0: "太古", 1: "上古", 2: "中古", 3: "近古", 4: "当世"}
	var era = entry.get("era_tag", 0)
	_content_label.append_text("[i][color=gray]— %s时代 —[/color][/i]\n\n" % era_names.get(era, "未知"))
	_content_label.append_text(entry.get("content", ""))


func _on_lore_unlock(condition: String) -> void:
	for entry_id in DataRegistry.world_lore:
		if entry_id in _unlocked_entries:
			continue
		var entry = DataRegistry.world_lore[entry_id]
		var cond = entry.get("unlock_condition", "")
		if cond == condition:
			_unlocked_entries.append(entry_id)
			EventBus.lore_unlocked.emit(entry_id)
