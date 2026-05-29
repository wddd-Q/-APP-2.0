class_name InputFeedbackLayer
extends Control
## Lightweight visual feedback layer for clicks and hoverable controls.

const MAX_RIPPLES := 18
const RIPPLE_DURATION := 0.48
const HOVER_TYPES := ["BaseButton", "LineEdit", "TextEdit", "SpinBox", "Slider", "OptionButton"]

var _ripples: Array[Dictionary] = []
var _hovered_controls: Array[Control] = []
var _cursor_pos := Vector2.ZERO
var _has_cursor := false
var _anim_time := 0.0
var _scan_timer := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 4096
	set_process(true)
	set_process_input(true)
	_bind_controls(get_tree().root)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_cursor_pos = event.position
		_has_cursor = true
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_add_click_ripple(event.position)


func _process(delta: float) -> void:
	_anim_time += delta
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = 1.0
		_bind_controls(get_tree().root)

	for i in range(_ripples.size() - 1, -1, -1):
		_ripples[i]["age"] = float(_ripples[i].get("age", 0.0)) + delta
		if float(_ripples[i]["age"]) >= RIPPLE_DURATION:
			_ripples.remove_at(i)

	_cleanup_hovered_controls()
	if visible:
		queue_redraw()


func _draw() -> void:
	_draw_hover_glow()
	_draw_click_ripples()
	_draw_cursor_aura()


func _add_click_ripple(position: Vector2) -> void:
	_ripples.append({
		"position": position,
		"age": 0.0,
	})
	while _ripples.size() > MAX_RIPPLES:
		_ripples.pop_front()
	queue_redraw()


func _draw_click_ripples() -> void:
	for ripple in _ripples:
		var t = clampf(float(ripple.get("age", 0.0)) / RIPPLE_DURATION, 0.0, 1.0)
		var pos: Vector2 = ripple.get("position", Vector2.ZERO)
		var alpha = 1.0 - t
		var radius = lerpf(8.0, 46.0, t)
		var inner = Color(0.94, 0.78, 0.34, 0.16 * alpha)
		var outer = Color(0.42, 0.78, 0.92, 0.55 * alpha)
		draw_circle(pos, radius * 0.36, inner)
		draw_arc(pos, radius, 0.0, TAU, 48, outer, 2.0, true)
		draw_arc(pos, radius * 0.58, 0.0, TAU, 48, Color(1.0, 0.94, 0.62, 0.35 * alpha), 1.4, true)


func _draw_cursor_aura() -> void:
	if not _has_cursor:
		return
	var pulse = 0.5 + 0.5 * sin(_anim_time * 5.0)
	draw_circle(_cursor_pos, 7.0 + pulse * 2.0, Color(0.95, 0.82, 0.35, 0.08))
	draw_arc(_cursor_pos, 12.0 + pulse * 1.5, 0.0, TAU, 32, Color(0.78, 0.92, 1.0, 0.16), 1.0, true)


func _draw_hover_glow() -> void:
	var pulse = 0.5 + 0.5 * sin(_anim_time * 4.0)
	for control in _hovered_controls:
		if not _can_draw_hover(control):
			continue
		var rect = control.get_global_rect().grow(3.0 + pulse * 1.5)
		var color = Color(0.95, 0.78, 0.32, 0.22 + pulse * 0.12)
		draw_rect(rect, color, false, 2.0)
		draw_rect(rect.grow(3.0), Color(0.35, 0.8, 0.95, 0.08 + pulse * 0.08), false, 1.0)


func _bind_controls(node: Node) -> void:
	if node is Control:
		_bind_control(node)
	for child in node.get_children():
		_bind_controls(child)


func _bind_control(control: Control) -> void:
	if control == self or control.has_meta("input_feedback_bound"):
		return
	if not _is_feedback_target(control):
		return
	control.set_meta("input_feedback_bound", true)
	control.mouse_entered.connect(_on_control_entered.bind(control))
	control.mouse_exited.connect(_on_control_exited.bind(control))


func _on_node_added(node: Node) -> void:
	if node is Control:
		call_deferred("_bind_controls", node)


func _on_control_entered(control: Control) -> void:
	if not _hovered_controls.has(control):
		_hovered_controls.append(control)
	queue_redraw()


func _on_control_exited(control: Control) -> void:
	_hovered_controls.erase(control)
	queue_redraw()


func _cleanup_hovered_controls() -> void:
	for i in range(_hovered_controls.size() - 1, -1, -1):
		if not _can_draw_hover(_hovered_controls[i]):
			_hovered_controls.remove_at(i)


func _is_feedback_target(control: Control) -> bool:
	for type_name in HOVER_TYPES:
		if control.is_class(type_name):
			return true
	return false


func _can_draw_hover(control: Control) -> bool:
	return is_instance_valid(control) and control.visible and control.is_visible_in_tree() and control.get_global_rect().size.length() > 4.0
