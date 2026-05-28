class_name SavePanel
extends Control
## 游戏内存档面板


var _slots_container: VBoxContainer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


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
	panel.size = Vector2(520, 460)
	panel.position = Vector2(get_viewport().get_visible_rect().size / 2 - panel.size / 2)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "存档 / 读档"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	# 存档操作行
	var save_row = HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 10)
	save_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(save_row)

	for i in range(3):
		var slot_name = "save_%d" % (i + 1)
		var btn = Button.new()
		btn.text = "存档 %d" % (i + 1)
		btn.pressed.connect(func(s=slot_name): _on_save(s))
		save_row.add_child(btn)

	# 存档列表
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 250)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_slots_container = VBoxContainer.new()
	_slots_container.add_theme_constant_override("separation", 6)
	scroll.add_child(_slots_container)

	# 返回主菜单
	var menu_btn = Button.new()
	menu_btn.text = "返回主菜单（请先存档）"
	menu_btn.pressed.connect(_on_return_to_menu)
	vbox.add_child(menu_btn)

	# 关闭
	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(func(): visible = false)
	vbox.add_child(close_btn)


func open_panel() -> void:
	visible = true
	_refresh_slots()


func _refresh_slots() -> void:
	for child in _slots_container.get_children():
		child.queue_free()

	var slots = SaveManager.get_save_slots()
	if slots.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无存档记录"
		_slots_container.add_child(lbl)
		return

	for slot in slots:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var info = Label.new()
		info.text = "[%s] %s — %s" % [slot["name"], slot["sect_name"], slot["date"]]
		info.add_theme_font_size_override("font_size", 16)
		row.add_child(info)

		var load_btn = Button.new()
		load_btn.text = "读档"
		var slot_path = slot["path"]
		load_btn.pressed.connect(func(): _on_load(slot_path))
		row.add_child(load_btn)

		_slots_container.add_child(row)


func _on_save(slot_name: String) -> void:
	var ok = GameManager.save_game(slot_name)
	if ok:
		_refresh_slots()
		print("游戏已保存到: %s" % slot_name)


func _on_load(path: String) -> void:
	GameManager.load_game(path)
	if GameManager.is_game_running():
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_return_to_menu() -> void:
	GameManager.game_initialized = false
	GameManager.current_sect = null
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
