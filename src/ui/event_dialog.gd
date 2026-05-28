extends Control
## 事件弹窗 — 显示随机事件和选项


@onready var event_title: Label = $Panel/EventTitle
@onready var event_description: Label = $Panel/EventDescription
@onready var choices_container: Control = $Panel/Choices


var _current_event: Dictionary = {}
var _result_label: Label


func _ready() -> void:
	EventBus.random_event_triggered.connect(_show_event)
	visible = false

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 18)
	_result_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$Panel.add_child(_result_label)
	$Panel.move_child(_result_label, $Panel.get_child_count() - 1)


func _show_event(event_id: String) -> void:
	for event in EventController.active_events:
		if event["id"] == event_id:
			_current_event = event
			_display_event(event)
			return


func _display_event(event: Dictionary) -> void:
	visible = true
	event_title.text = event.get("name", "事件")
	event_description.text = event.get("description", "")
	_result_label.text = ""

	for child in choices_container.get_children():
		child.queue_free()

	var choices = event.get("choices", [])
	for i in range(choices.size()):
		var choice = choices[i]
		var btn = Button.new()
		btn.text = "%d. %s" % [i + 1, choice.get("label", "选项")]
		var choice_idx = i
		btn.pressed.connect(func(): _on_choice_selected(choice_idx))
		choices_container.add_child(btn)


func _on_choice_selected(choice: int) -> void:
	var result = EventController.resolve_choice(_current_event["id"], choice)

	for child in choices_container.get_children():
		child.queue_free()

	if result.has("messages") and not result["messages"].is_empty():
		_result_label.text = "\n".join(result["messages"])
	elif result.has("error"):
		_result_label.text = result["error"]

	var close_btn = Button.new()
	close_btn.text = "确定"
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(func(): visible = false)
	choices_container.add_child(close_btn)

	if result.has("effects_applied"):
		print("事件结果: ", result)
