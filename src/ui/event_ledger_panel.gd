class_name EventLedgerPanel
extends Control
## 宗门纪事面板：整理待处理事件、持续影响和事件归档。


var _pending_list: VBoxContainer
var _impact_list: VBoxContainer
var _history_list: VBoxContainer
var _empty_label: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	EventBus.event_ledger_changed.connect(_refresh_if_visible)
	EventBus.random_event_triggered.connect(func(_event_id: String): _refresh_if_visible())
	EventBus.event_choice_made.connect(func(_event_id: String, _choice: int): _refresh_if_visible())


func open_panel() -> void:
	visible = true
	EventController.mark_events_read()
	_refresh()


func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.62)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			visible = false
	)
	add_child(bg)

	var panel = Panel.new()
	panel.size = Vector2(1120, 700)
	panel.position = Vector2(get_viewport().get_visible_rect().size / 2 - panel.size / 2)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var root = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	root.offset_left = 18
	root.offset_top = 14
	root.offset_right = -18
	root.offset_bottom = -14
	panel.add_child(root)

	var title_bar = HBoxContainer.new()
	title_bar.add_theme_constant_override("separation", 10)
	root.add_child(title_bar)

	var title = Label.new()
	title.text = "宗门纪事"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.84, 0.56, 1.0))
	title_bar.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "整理突发事件、选择结果与后续影响"
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.74, 0.7, 0.58, 1.0))
	title_bar.add_child(subtitle)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(func(): visible = false)
	title_bar.add_child(close_btn)

	var columns = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	root.add_child(columns)

	_pending_list = _make_column(columns, "待处理", Vector2(500, 0))
	_impact_list = _make_column(columns, "影响中", Vector2(260, 0))
	_history_list = _make_column(columns, "归档", Vector2(300, 0))

	_empty_label = Label.new()
	_empty_label.text = "暂无纪事"
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.add_theme_font_size_override("font_size", 18)
	_empty_label.add_theme_color_override("font_color", Color(0.68, 0.64, 0.52, 1.0))
	root.add_child(_empty_label)


func _make_column(parent: Control, title_text: String, min_size: Vector2) -> VBoxContainer:
	var column = VBoxContainer.new()
	column.custom_minimum_size = min_size
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	parent.add_child(column)

	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.9, 0.84, 0.56, 1.0))
	column.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	return list


func _refresh_if_visible() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	_clear_list(_pending_list)
	_clear_list(_impact_list)
	_clear_list(_history_list)

	for event in EventController.active_events:
		_pending_list.add_child(_make_pending_card(event))

	for impact in EventController.active_impacts:
		_impact_list.add_child(_make_impact_card(impact))

	var count = 0
	for record in EventController.event_records:
		if count >= 30:
			break
		_history_list.add_child(_make_history_card(record))
		count += 1

	_add_empty_hint(_pending_list, "当前没有待处理事件")
	_add_empty_hint(_impact_list, "没有持续影响")
	_add_empty_hint(_history_list, "还没有事件归档")
	_empty_label.visible = (
		EventController.active_events.is_empty()
		and EventController.active_impacts.is_empty()
		and EventController.event_records.is_empty()
	)


func _clear_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()


func _add_empty_hint(list: VBoxContainer, text: String) -> void:
	if list.get_child_count() > 0:
		return
	var hint = Label.new()
	hint.text = text
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.add_theme_color_override("font_color", Color(0.62, 0.59, 0.5, 1.0))
	list.add_child(hint)


func _make_pending_card(event: Dictionary) -> Control:
	var card = _make_card()
	var title = _make_card_title("%s · %s" % [event.get("name", "事件"), event.get("rarity", "common")])
	card.add_child(title)

	var desc = Label.new()
	desc.text = event.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 14)
	card.add_child(desc)

	var handler_label = Label.new()
	handler_label.text = "委派处理:"
	handler_label.add_theme_font_size_override("font_size", 14)
	handler_label.add_theme_color_override("font_color", Color(0.78, 0.72, 0.56, 1.0))
	card.add_child(handler_label)

	var handler_selector = OptionButton.new()
	var handlers = EventController.get_event_handlers()
	for handler in handlers:
		handler_selector.add_item("%s  %s" % [handler.get("name", ""), handler.get("hint", "")])
		handler_selector.set_item_metadata(handler_selector.item_count - 1, handler.get("id", ""))
	if handler_selector.item_count > 0:
		handler_selector.select(0)
	card.add_child(handler_selector)

	var choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 6)
	card.add_child(choices_box)

	var rebuild_choices = func() -> void:
		for child in choices_box.get_children():
			child.queue_free()
		var handler_id = ""
		if handler_selector.item_count > 0:
			var selected_idx = maxi(0, handler_selector.selected)
			handler_id = str(handler_selector.get_item_metadata(selected_idx))
		var choices = event.get("choices", [])
		if choices.is_empty():
			_add_empty_hint(choices_box, "此事件暂无可选处理方案")
			return

		var choice_selector = OptionButton.new()
		choice_selector.add_theme_font_size_override("font_size", 14)
		for i in range(choices.size()):
			var choice = choices[i]
			var judgement = EventController.get_choice_judgement(event.get("id", ""), i, handler_id)
			choice_selector.add_item("%d. %s  [%s]" % [i + 1, choice.get("label", "选项"), judgement.get("label", "可接受")])
			choice_selector.set_item_metadata(choice_selector.item_count - 1, i)
		choice_selector.select(0)
		choices_box.add_child(choice_selector)

		var detail = Label.new()
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD
		detail.add_theme_font_size_override("font_size", 13)
		choices_box.add_child(detail)

		var confirm_btn = Button.new()
		confirm_btn.text = "确认处理所选方案"
		confirm_btn.add_theme_font_size_override("font_size", 15)
		choices_box.add_child(confirm_btn)

		var update_choice_preview = func(_idx: int = 0) -> void:
			var selected_choice = int(choice_selector.get_item_metadata(maxi(0, choice_selector.selected)))
			var judgement = EventController.get_choice_judgement(event.get("id", ""), selected_choice, handler_id)
			var influence = EventController.get_handler_influence_preview(event.get("id", ""), selected_choice, handler_id)
			detail.text = "判断：%s\n%s\n性格影响：%s\n\n选择方案后不会立刻结算，点击下方确认按钮才会处理。" % [
				judgement.get("label", "可接受"),
				judgement.get("reason", ""),
				influence,
			]
			detail.add_theme_color_override("font_color", _get_judgement_color(int(judgement.get("score", 0))))

		choice_selector.item_selected.connect(func(idx: int): update_choice_preview.call(idx))
		confirm_btn.pressed.connect(func():
			var selected_choice = int(choice_selector.get_item_metadata(maxi(0, choice_selector.selected)))
			_resolve_pending_choice(event.get("id", ""), selected_choice, handler_id)
		)
		update_choice_preview.call()

	handler_selector.item_selected.connect(func(_idx: int): rebuild_choices.call())
	rebuild_choices.call()
	return card


func _make_choice_row(event: Dictionary, choice: Dictionary, choice_idx: int, handler_id: String, judgement: Dictionary) -> Control:
	var row = VBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var btn = Button.new()
	btn.text = "%d. %s  [%s]" % [choice_idx + 1, choice.get("label", "选项"), judgement.get("label", "可接受")]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(func(): _resolve_pending_choice(event.get("id", ""), choice_idx, handler_id))
	row.add_child(btn)

	var reason = Label.new()
	reason.text = judgement.get("reason", "")
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD
	reason.add_theme_font_size_override("font_size", 12)
	reason.add_theme_color_override("font_color", _get_judgement_color(int(judgement.get("score", 0))))
	row.add_child(reason)
	return row


func _resolve_pending_choice(event_id: String, choice_idx: int, handler_id: String) -> void:
	EventController.resolve_choice(event_id, choice_idx, handler_id)
	_refresh()


func _make_impact_card(impact: Dictionary) -> Control:
	var card = _make_card()
	var title = _make_card_title("%s  ·  剩余%d月" % [impact.get("title", "影响"), impact.get("months_remaining", 0)])
	card.add_child(title)

	var summary = Label.new()
	summary.text = impact.get("summary", "")
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD
	summary.add_theme_font_size_override("font_size", 14)
	summary.add_theme_color_override("font_color", _get_severity_color(impact.get("severity", "neutral")))
	card.add_child(summary)
	return card


func _make_history_card(record: Dictionary) -> Control:
	var card = _make_card()
	var title = _make_card_title("%s  [%s]" % [record.get("title", "事件"), record.get("date", "")])
	card.add_child(title)

	var body = RichTextLabel.new()
	body.custom_minimum_size = Vector2(0, 118)
	body.fit_content = true
	body.bbcode_enabled = true
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.add_theme_font_size_override("normal_font_size", 14)
	body.append_text("[color=#d6c98e]%s / %s[/color]\n" % [record.get("scope", "宗门"), record.get("rarity", "常见")])
	var handler = record.get("handler", {})
	var judgement = record.get("handler_judgement", {})
	if not handler.is_empty():
		body.append_text("处理：%s（%s）" % [handler.get("name", "掌门"), handler.get("position", "掌门")])
		if not judgement.is_empty():
			body.append_text(" · %s" % judgement.get("label", "可接受"))
		body.append_text("\n")
		var influence = record.get("handler_influence", {})
		if not influence.is_empty():
			body.append_text("性格影响：%s\n" % influence.get("summary", ""))
	body.append_text("选择：%s\n" % record.get("choice", ""))
	body.append_text("即时：%s\n" % record.get("immediate", ""))
	body.append_text("后续：%s" % record.get("long_term", "无持续影响"))
	card.add_child(body)
	return card


func _make_card() -> VBoxContainer:
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 5)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.07, 0.88)
	style.border_color = Color(0.55, 0.45, 0.25, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", style)
	return card


func _make_card_title(text: String) -> Label:
	var title = Label.new()
	title.text = text
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.92, 0.82, 0.48, 1.0))
	return title


func _get_severity_color(severity: String) -> Color:
	match severity:
		"good":
			return Color(0.58, 0.92, 0.62, 1.0)
		"warning":
			return Color(1.0, 0.72, 0.38, 1.0)
		"bad":
			return Color(1.0, 0.45, 0.42, 1.0)
		_:
			return Color(0.86, 0.82, 0.7, 1.0)


func _get_judgement_color(score: int) -> Color:
	if score >= 2:
		return Color(0.58, 0.92, 0.62, 1.0)
	if score <= -2:
		return Color(1.0, 0.62, 0.44, 1.0)
	return Color(0.72, 0.68, 0.56, 1.0)
