class_name WorldMapPanel
extends Control
## 世界地图面板：AI 地图底图 + 数据驱动交互标记。

const WORLD_MAP_PATH := "res://assets/textures/maps/world_map.png"

var _map_canvas: Control
var _detail_title: Label
var _detail_info: RichTextLabel
var _world_log: RichTextLabel
var _selected_region: String = ""
var _marker_nodes: Array[Control] = []
var _animation_layer: Control
var _anim_time: float = 0.0


func _ready() -> void:
	_build_ui()
	set_process(true)
	EventBus.year_passed.connect(_on_year_passed)
	EventBus.game_started.connect(_refresh)
	EventBus.event_ledger_changed.connect(_refresh)
	call_deferred("_refresh")


func _build_ui() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	var title = Label.new()
	title.text = "修真界局势图"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	vbox.add_child(title)

	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(main_hbox)

	_map_canvas = Control.new()
	_map_canvas.custom_minimum_size = Vector2(980, 560)
	_map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_canvas.clip_contents = true
	main_hbox.add_child(_map_canvas)

	var map_bg = TextureRect.new()
	map_bg.name = "MapBackground"
	map_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_bg.texture = _load_texture(WORLD_MAP_PATH)
	_map_canvas.add_child(map_bg)

	var shade = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.08)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_canvas.add_child(shade)

	_animation_layer = Control.new()
	_animation_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_animation_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_animation_layer.draw.connect(_draw_dynamic_world)
	_map_canvas.add_child(_animation_layer)

	var detail_panel = VBoxContainer.new()
	detail_panel.custom_minimum_size = Vector2(340, 0)
	detail_panel.add_theme_constant_override("separation", 10)
	main_hbox.add_child(detail_panel)

	_detail_title = Label.new()
	_detail_title.text = "区域详情"
	_detail_title.add_theme_font_size_override("font_size", 22)
	_detail_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	detail_panel.add_child(_detail_title)

	_detail_info = RichTextLabel.new()
	_detail_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_info.bbcode_enabled = true
	_detail_info.add_theme_font_size_override("normal_font_size", 15)
	detail_panel.add_child(_detail_info)

	var log_section = VBoxContainer.new()
	log_section.add_theme_constant_override("separation", 5)
	vbox.add_child(log_section)

	var log_title = Label.new()
	log_title.text = "天下传闻"
	log_title.add_theme_font_size_override("font_size", 20)
	log_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	log_section.add_child(log_title)

	_world_log = RichTextLabel.new()
	_world_log.custom_minimum_size = Vector2(0, 95)
	_world_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_world_log.bbcode_enabled = true
	_world_log.scroll_following = true
	log_section.add_child(_world_log)
	_world_log.append_text("宗门历1年春 - 苍梧旧约尚在，但魔渊与古战场已有异动传闻。\n")


func _refresh() -> void:
	if not _map_canvas:
		return
	for marker in _marker_nodes:
		if is_instance_valid(marker):
			marker.queue_free()
	_marker_nodes.clear()

	_add_region_markers()
	_add_incident_markers()
	if _selected_region == "":
		_show_world_summary()
	else:
		_refresh_detail(_selected_region)
	if _animation_layer:
		_animation_layer.queue_redraw()


func _process(delta: float) -> void:
	_anim_time += delta
	if visible and _animation_layer:
		_animation_layer.queue_redraw()


func _add_region_markers() -> void:
	for region_id in DataRegistry.map_regions:
		var r = DataRegistry.map_regions[region_id]
		var controller = WorldController.get_region_controller(region_id)
		var has_location = not r.get("special_locations", []).is_empty()
		if controller == "" and not has_location and region_id != "player_home":
			continue

		var rid = region_id
		var marker = _make_marker(_get_region_marker_text(rid, controller, has_location), _get_region_marker_color(rid, controller))
		marker.tooltip_text = r.get("name", region_id)
		marker.pressed.connect(func(): _on_region_clicked(rid))
		_place_marker(marker, r["grid_x"], r["grid_y"], Vector2.ZERO)


func _add_incident_markers() -> void:
	for incident in WorldController.get_world_incidents():
		var region = DataRegistry.map_regions.get(incident.get("region_id", ""), {})
		if region.is_empty():
			continue
		var incident_data = incident.duplicate(true)
		var marker = _make_marker(_get_incident_icon(incident_data.get("type", "")), _get_incident_color(incident_data.get("severity", "low")))
		marker.tooltip_text = "%s：%s" % [incident.get("type", "异动"), incident.get("name", "")]
		marker.pressed.connect(func(): _show_incident_detail(incident_data))
		_place_marker(marker, region["grid_x"], region["grid_y"], Vector2(18, -16))


func _place_marker(marker: Button, grid_x: int, grid_y: int, offset: Vector2) -> void:
	_map_canvas.add_child(marker)
	_marker_nodes.append(marker)
	var map_size = _map_canvas.size
	if map_size.x <= 0 or map_size.y <= 0:
		map_size = _map_canvas.custom_minimum_size
	var pos = Vector2(
		(float(grid_x) + 0.5) / 6.0 * map_size.x,
		(float(grid_y) + 0.5) / 5.0 * map_size.y
	)
	marker.position = pos - marker.custom_minimum_size * 0.5 + offset


func _draw_dynamic_world() -> void:
	if not _animation_layer:
		return
	var size = _animation_layer.size
	var pulse = 0.5 + 0.5 * sin(_anim_time * 2.2)

	# 灵气流向与局势线，让地图像一张正在被掌门观测的局势盘。
	var home = _grid_to_canvas_pos(2, 2, size)
	var sealing = _grid_to_canvas_pos(2, 4, size)
	var central = _grid_to_canvas_pos(2, 1, size)
	_animation_layer.draw_line(home, central, Color(0.35, 0.65, 0.9, 0.22 + pulse * 0.12), 2.0)
	_animation_layer.draw_line(sealing, home, Color(0.62, 0.12, 0.2, 0.18 + pulse * 0.18), 2.0)

	for incident in WorldController.get_world_incidents():
		var region = DataRegistry.map_regions.get(incident.get("region_id", ""), {})
		if region.is_empty():
			continue
		var pos = _grid_to_canvas_pos(region.get("grid_x", 0), region.get("grid_y", 0), size) + Vector2(18, -16)
		var color = _get_incident_color(incident.get("severity", "low"))
		var radius = 18.0 + pulse * 12.0
		_animation_layer.draw_circle(pos, radius, Color(color.r, color.g, color.b, 0.12 + pulse * 0.10))
		_animation_layer.draw_circle(pos, radius + 8.0, Color(color.r, color.g, color.b, 0.10), false, 2.0)

	if _selected_region != "":
		var selected = DataRegistry.map_regions.get(_selected_region, {})
		if not selected.is_empty():
			var selected_pos = _grid_to_canvas_pos(selected.get("grid_x", 0), selected.get("grid_y", 0), size)
			_animation_layer.draw_circle(selected_pos, 30.0 + pulse * 5.0, Color(0.95, 0.82, 0.32, 0.2), false, 3.0)


func _grid_to_canvas_pos(grid_x: int, grid_y: int, map_size: Vector2) -> Vector2:
	return Vector2(
		(float(grid_x) + 0.5) / 6.0 * map_size.x,
		(float(grid_y) + 0.5) / 5.0 * map_size.y
	)


func _make_marker(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(34, 34)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color.WHITE)
	var normal = StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_color = Color(0.1, 0.08, 0.04, 0.9)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(17)
	btn.add_theme_stylebox_override("normal", normal)

	var hover = normal.duplicate()
	hover.bg_color = color.lightened(0.18)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", normal)
	return btn


func _on_region_clicked(region_id: String) -> void:
	_selected_region = region_id
	_refresh_detail(region_id)
	EventBus.lore_unlocked.emit("discover_region:%s" % region_id)


func _refresh_detail(region_id: String) -> void:
	var r = DataRegistry.map_regions.get(region_id, {})
	if r.is_empty():
		return

	var controller = WorldController.get_region_controller(region_id)
	var controller_text = controller if controller != "" else "无主之地"
	if controller == "本门":
		controller_text = "[color=#E6D633]本门[/color]"

	var terrain_names = {"plain": "平原", "mountain": "山地", "forest": "森林",
		"desert": "沙漠", "river": "水域", "swamp": "沼泽", "volcano": "火山"}

	_detail_title.text = r["name"]
	_detail_info.clear()
	_detail_info.append_text("[b]%s[/b]\n\n" % r["name"])
	_detail_info.append_text("地形: %s %s\n" % [terrain_names.get(r["terrain"], "未知"), DataRegistry.get_terrain_icon(r["terrain"])])
	_detail_info.append_text("灵气: [color=#88BBFF]%d[/color]\n" % r["spiritual_density"])
	_detail_info.append_text("危险: [color=#FF8888]%d[/color]\n" % r["danger_level"])
	_detail_info.append_text("控制者: %s\n\n" % controller_text)

	for faction in WorldController.npc_factions:
		if faction.home_region == region_id and faction.is_alive:
			var karma_text = "正道" if faction.karma > 20 else ("魔道" if faction.karma < -20 else "中立")
			_detail_info.append_text("[b]%s[/b] [%s] | %s\n" % [
				faction.faction_name,
				karma_text,
				DataRegistry.get_realm_name(faction.faction_realm),
			])
			_detail_info.append_text("弟子: %d | 战力: %d | 关系: %+d\n\n" % [
				faction.disciples.size(),
				faction.combat_power,
				faction.relation_to_player,
			])

	_detail_info.append_text("%s\n\n" % r["description"])

	var region_incidents = WorldController.get_world_incidents().filter(func(i): return i.get("region_id", "") == region_id)
	if not region_incidents.is_empty():
		_detail_info.append_text("[b]当前异动:[/b]\n")
		for incident in region_incidents:
			_detail_info.append_text("· %s：%s\n" % [incident.get("type", "异动"), incident.get("name", "")])
			_detail_info.append_text("  %s\n" % incident.get("description", ""))
		_detail_info.append_text("\n")

	if not r["special_locations"].is_empty():
		_detail_info.append_text("[b]特殊地点:[/b]\n")
		for loc in r["special_locations"]:
			var dungeon = DataRegistry.dungeon_templates.get(loc, {})
			if not dungeon.is_empty():
				var dname = dungeon.get("dungeon_name", loc)
				var diff = dungeon.get("difficulty", 1)
				var stars = ""
				for _i in range(diff):
					stars += "*"
				_detail_info.append_text("· %s [%s]\n" % [dname, stars])


func _show_incident_detail(incident: Dictionary) -> void:
	var region = DataRegistry.map_regions.get(incident.get("region_id", ""), {})
	_selected_region = incident.get("region_id", "")
	_detail_title.text = incident.get("name", "天下异动")
	_detail_info.clear()
	_detail_info.append_text("[b]%s[/b]\n" % incident.get("type", "异动"))
	if not region.is_empty():
		_detail_info.append_text("区域: %s\n" % region.get("name", "未知"))
	_detail_info.append_text("危险: %s\n\n" % _get_severity_label(incident.get("severity", "low")))
	_detail_info.append_text("%s\n\n" % incident.get("description", ""))
	_detail_info.append_text("[color=#d8c57a]这类世界异动只提供线索与局势压力，不会强制推动主线。[/color]")
	EventBus.lore_unlocked.emit("world_incident:%s" % incident.get("id", ""))


func _show_world_summary() -> void:
	_detail_title.text = "天下概览"
	_detail_info.clear()
	_detail_info.append_text("点击地图上的宗门、秘境或异动标记查看详情。\n\n")
	_detail_info.append_text("[b]标记说明[/b]\n")
	_detail_info.append_text("本：本门山门\n宗：其他宗门\n秘：秘境或资源点\n战：人魔战线\n妖：妖兽入侵\n疑：宗门疑云\n")


func _on_year_passed(year: int) -> void:
	_refresh()
	_add_world_log_entry("宗门历%d年 - 天下势力格局悄然变化，新的传闻传入山门。" % year)


func _add_world_log_entry(text: String) -> void:
	_world_log.append_text(text + "\n")


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img = Image.new()
	var err = img.load(ProjectSettings.globalize_path(path))
	if err == OK:
		return ImageTexture.create_from_image(img)
	return null


func _get_region_marker_text(region_id: String, controller: String, has_location: bool) -> String:
	if region_id == "player_home":
		return "本"
	if controller != "":
		return "宗"
	if has_location:
		return "秘"
	return "地"


func _get_region_marker_color(region_id: String, controller: String) -> Color:
	if region_id == "player_home":
		return Color(0.82, 0.62, 0.18, 0.95)
	if controller == "":
		return Color(0.35, 0.45, 0.58, 0.9)
	for faction in WorldController.npc_factions:
		if faction.faction_name == controller:
			if faction.karma > 20:
				return Color(0.23, 0.55, 0.32, 0.92)
			if faction.karma < -20:
				return Color(0.55, 0.18, 0.22, 0.92)
	return Color(0.42, 0.42, 0.42, 0.9)


func _get_incident_icon(incident_type: String) -> String:
	match incident_type:
		"人魔战线":
			return "战"
		"妖兽入侵":
			return "妖"
		"宗门疑云":
			return "疑"
		_:
			return "!"


func _get_incident_color(severity: String) -> Color:
	match severity:
		"high":
			return Color(0.62, 0.08, 0.12, 0.96)
		"medium":
			return Color(0.78, 0.36, 0.1, 0.96)
		_:
			return Color(0.45, 0.25, 0.66, 0.94)


func _get_severity_label(severity: String) -> String:
	match severity:
		"high":
			return "高"
		"medium":
			return "中"
		_:
			return "低"
