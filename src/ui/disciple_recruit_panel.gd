class_name DiscipleRecruitPanel
extends Control
## 弟子招收面板


var _candidates: Array[Dictionary] = []
var _detection_cost: int = 30

var _candidates_list: VBoxContainer
var _cost_label: Label


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

	# 主面板
	var panel = Panel.new()
	panel.size = Vector2(620, 520)
	panel.position = Vector2(get_viewport().get_visible_rect().size / 2 - panel.size / 2)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	# 标题
	var title = Label.new()
	title.text = "招收弟子"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	# 费用标签
	_cost_label = Label.new()
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_cost_label)

	# 候选人列表
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 300)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_candidates_list = VBoxContainer.new()
	_candidates_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_candidates_list)

	# 关闭按钮
	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(func(): visible = false)
	vbox.add_child(close_btn)


func open_panel() -> void:
	visible = true
	var cost = 50 + randi() % 100
	_cost_label.text = "发布招徒令: %d 灵石" % cost

	if sector_can_afford(cost):
		var sect = GameManager.current_sect
		sect.spend_spirit_stones(cost)
		EventBus.spirit_stones_changed.emit(sect.spirit_stones, -cost)
		_candidates = RecruitmentController.generate_candidates(4)
		_display_candidates()
	else:
		_show_insufficient_funds()


func _display_candidates() -> void:
	for child in _candidates_list.get_children():
		child.queue_free()

	for i in range(_candidates.size()):
		var c = _candidates[i]
		var card = _create_candidate_card(c, i)
		_candidates_list.add_child(card)


func _create_candidate_card(candidate: Dictionary, idx: int) -> Control:
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 5)

	var name_label = Label.new()
	name_label.text = "%d. %s  %d岁  %s" % [
		idx + 1,
		candidate["name"],
		candidate["age"],
		"男" if candidate["gender"] == 0 else "女",
	]
	name_label.add_theme_font_size_override("font_size", 20)
	card.add_child(name_label)

	var hint = Label.new()
	hint.text = _get_attribute_summary(candidate)
	hint.add_theme_font_size_override("font_size", 16)
	card.add_child(hint)

	var specialty = Label.new()
	specialty.text = "擅长: %s  |  性格: %s" % [
		candidate.get("specialty", "未明"),
		", ".join(candidate.get("personalities", [])),
	]
	specialty.add_theme_font_size_override("font_size", 15)
	card.add_child(specialty)

	var story = Label.new()
	story.text = candidate.get("origin_story", "来历未明")
	story.autowrap_mode = TextServer.AUTOWRAP_WORD
	story.add_theme_font_size_override("font_size", 14)
	story.add_theme_color_override("font_color", Color(0.75, 0.7, 0.58, 1.0))
	card.add_child(story)

	var root_label = Label.new()
	if candidate["root_revealed"]:
		root_label.text = "灵根: " + candidate["root_name"]
	else:
		root_label.text = "灵根: ??? [检测 %d灵石]" % _detection_cost
	root_label.add_theme_font_size_override("font_size", 16)
	card.add_child(root_label)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)

	if not candidate["root_revealed"]:
		var detect_btn = Button.new()
		detect_btn.text = "检测灵根 (%d灵石)" % _detection_cost
		detect_btn.pressed.connect(func(): _on_detect(idx))
		btn_row.add_child(detect_btn)

	var recruit_btn = Button.new()
	recruit_btn.text = "招收 (%d灵石)" % candidate.get("recruit_cost", 50)
	recruit_btn.pressed.connect(func(): _on_recruit(idx))
	btn_row.add_child(recruit_btn)

	card.add_child(btn_row)
	card.add_child(HSeparator.new())

	return card


func _on_detect(idx: int) -> void:
	var sect = GameManager.current_sect
	if not sect or sect.spirit_stones < _detection_cost:
		return
	sect.spend_spirit_stones(_detection_cost)
	RecruitmentController.detect_spirit_root(_candidates[idx])
	EventBus.spirit_stones_changed.emit(sect.spirit_stones, -_detection_cost)
	_display_candidates()


func _on_recruit(idx: int) -> void:
	var d = RecruitmentController.recruit(_candidates[idx])
	if d:
		_candidates.remove_at(idx)
		_display_candidates()
		if _candidates.is_empty():
			visible = false


func _get_attribute_summary(candidate: Dictionary) -> String:
	var parts: Array[String] = []
	if candidate["bone_structure"] >= 70: parts.append("根骨上佳")
	elif candidate["bone_structure"] >= 50: parts.append("根骨尚可")
	if candidate["comprehension"] >= 70: parts.append("天资聪颖")
	if candidate["fortune"] >= 70: parts.append("福缘深厚")
	if candidate["mentality"] >= 70: parts.append("心性坚韧")
	if candidate["talent"] >= 70: parts.append("资质出众")
	if parts.is_empty():
		parts.append("资质平平")
	return ", ".join(parts)


func _show_insufficient_funds() -> void:
	for child in _candidates_list.get_children():
		child.queue_free()
	var label = Label.new()
	label.text = "灵石不足，无法发布招徒令"
	label.add_theme_color_override("font_color", Color.RED)
	_candidates_list.add_child(label)


func sector_can_afford(amount: int) -> bool:
	var sect = GameManager.current_sect
	return sect and sect.spirit_stones >= amount
