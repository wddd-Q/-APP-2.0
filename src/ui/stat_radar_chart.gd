class_name StatRadarChart
extends Control
## 六维/多维雷达图 — 纯绘制


var _labels: Array[String] = []
var _values: Array[float] = []
var _fill_color: Color = Color(0.3, 0.7, 1.0, 0.3)
var _line_color: Color = Color(0.3, 0.7, 1.0, 0.8)
var _text_color: Color = Color(0.9, 0.9, 0.9, 1.0)
var _grid_color: Color = Color(0.3, 0.3, 0.3, 0.6)


func setup(labels: Array[String], values: Array[float], fill_clr: Color = Color(0.3, 0.7, 1.0, 0.3), line_clr: Color = Color(0.3, 0.7, 1.0, 0.8)) -> void:
	_labels = labels
	_values = values
	_fill_color = fill_clr
	_line_color = line_clr
	queue_redraw()


func _draw() -> void:
	if _labels.is_empty() or _values.is_empty():
		return

	var count = _labels.size()
	var center = Vector2(size.x / 2.0, size.y / 2.0)
	var radius = minf(size.x, size.y) / 2.0 - 25
	var angle_step = TAU / count
	var start_angle = -PI / 2.0  # 从顶部开始

	# 计算所有顶点
	var vertices: Array[Vector2] = []
	for i in range(count):
		var angle = start_angle + i * angle_step
		vertices.append(center + Vector2(cos(angle), sin(angle)) * radius)

	# 绘制网格圈 (3圈: 33%, 66%, 100%)
	for ring in [0.33, 0.66, 1.0]:
		var ring_pts: Array[Vector2] = []
		for v in vertices:
			ring_pts.append(center + (v - center) * ring)
		for j in range(count):
			var next_j = (j + 1) % count
			draw_line(ring_pts[j], ring_pts[next_j], _grid_color, 1.0)

	# 绘制轴线
	for v in vertices:
		draw_line(center, v, _grid_color, 1.0)

	# 绘制数值多边形
	var data_pts: Array[Vector2] = []
	for i in range(count):
		var val = clampf(_values[i] / 100.0, 0.0, 1.0)
		data_pts.append(center + (vertices[i] - center) * val)

	if data_pts.size() >= 3:
		draw_colored_polygon(data_pts, _fill_color)
	for j in range(count):
		var next_j = (j + 1) % count
		draw_line(data_pts[j], data_pts[next_j], _line_color, 2.0)

	# 绘制数值点
	for i in range(count):
		draw_circle(data_pts[i], 4, _line_color)

	# 绘制标签
	for i in range(count):
		var angle = start_angle + i * angle_step
		var label_pos = center + Vector2(cos(angle), sin(angle)) * (radius + 18)
		var font_size = 13
		draw_string(ThemeDB.fallback_font,
			label_pos - Vector2(font_size * _labels[i].length() * 0.3, font_size * 0.35),
			_labels[i],
			HORIZONTAL_ALIGNMENT_CENTER, -1, font_size,
			_text_color
		)
		# 数值标签
		var val_text = str(int(_values[i]))
		var val_pos = center + Vector2(cos(angle), sin(angle)) * (radius * 0.5)
		draw_string(ThemeDB.fallback_font,
			val_pos - Vector2(font_size * 0.5, font_size * 0.35),
			val_text,
			HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 1,
			Color.WHITE
		)
