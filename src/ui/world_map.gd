class_name WorldMapPanel
extends Control
## 世界地图面板 — 网格地理地图


var _detail_panel: VBoxContainer
var _detail_title: Label
var _detail_info: RichTextLabel
var _world_log: RichTextLabel
var _selected_region: String = ""
var _grid_cells: Dictionary = {}


func _ready() -> void:
	_build_ui()
	EventBus.year_passed.connect(_on_year_passed)
	EventBus.game_started.connect(_refresh)


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

	# 左侧：网格地图
	var map_container = VBoxContainer.new()
	map_container.custom_minimum_size = Vector2(660, 500)
	main_hbox.add_child(map_container)

	var grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	map_container.add_child(grid)

	# 构建 5行 x 6列 = 30个格子
	for row in range(5):
		for col in range(6):
			var cell = _make_grid_cell(col, row)
			grid.add_child(cell)

	# 右侧：区域详情
	_detail_panel = VBoxContainer.new()
	_detail_panel.custom_minimum_size = Vector2(260, 0)
	_detail_panel.add_theme_constant_override("separation", 10)
	main_hbox.add_child(_detail_panel)

	_detail_title = Label.new()
	_detail_title.text = "区域详情"
	_detail_title.add_theme_font_size_override("font_size", 22)
	_detail_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	_detail_panel.add_child(_detail_title)

	_detail_info = RichTextLabel.new()
	_detail_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_info.bbcode_enabled = true
	_detail_info.add_theme_font_size_override("normal_font_size", 15)
	_detail_panel.add_child(_detail_info)

	# 底部：大事记
	var log_section = VBoxContainer.new()
	log_section.add_theme_constant_override("separation", 5)
	vbox.add_child(log_section)

	var log_title = Label.new()
	log_title.text = "修真界大事记"
	log_title.add_theme_font_size_override("font_size", 20)
	log_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	log_section.add_child(log_title)

	_world_log = RichTextLabel.new()
	_world_log.custom_minimum_size = Vector2(0, 100)
	_world_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_world_log.bbcode_enabled = true
	_world_log.scroll_following = true
	log_section.add_child(_world_log)

	_world_log.append_text("宗门历1年春 — 修真界局势初定，各大势力蠢蠢欲动……\n")


func _make_grid_cell(col: int, row: int) -> Control:
	var cell = Panel.new()
	cell.custom_minimum_size = Vector2(105, 80)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_on_cell_clicked(col, row)
	)

	# 内部布局
	var inner = VBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("separation", 0)
	inner.mouse_filter = Control.MOUSE_FILTER_PASS
	cell.add_child(inner)

	var name_label = Label.new()
	name_label.text = "???"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.add_child(name_label)

	var terrain_label = Label.new()
	terrain_label.text = ""
	terrain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	terrain_label.add_theme_font_size_override("font_size", 20)
	terrain_label.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.add_child(terrain_label)

	_grid_cells[Vector2i(col, row)] = {
		"panel": cell, "name_label": name_label, "terrain_label": terrain_label,
	}
	return cell


func _on_cell_clicked(col: int, row: int) -> void:
	# 找到该格对应的区域
	for region_id in DataRegistry.map_regions:
		var r = DataRegistry.map_regions[region_id]
		if r["grid_x"] == col and r["grid_y"] == row:
			_selected_region = region_id
			_refresh_detail(region_id)
			# 触发背景故事解锁
			EventBus.lore_unlocked.emit("discover_region:%s" % region_id)
			return


func _refresh() -> void:
	for region_id in DataRegistry.map_regions:
		var r = DataRegistry.map_regions[region_id]
		var col = r["grid_x"]
		var row = r["grid_y"]
		var key = Vector2i(col, row)
		if not _grid_cells.has(key):
			continue

		var cell_data = _grid_cells[key]
		var panel: Panel = cell_data["panel"]
		var name_label: Label = cell_data["name_label"]
		var terrain_label: Label = cell_data["terrain_label"]

		# 背景色 = 地形色
		var terrain_color = DataRegistry.get_terrain_color(r["terrain"])
		var style = StyleBoxFlat.new()
		style.bg_color = terrain_color
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4

		# 边框 = 势力归属色
		var controller = WorldController.get_region_controller(region_id)
		if controller == "本门":
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_color = Color(0.9, 0.85, 0.2)  # 金色
		elif controller != "":
			# 查找该势力阵营
			for faction in WorldController.npc_factions:
				if faction.faction_name == controller:
					style.border_width_left = 2
					style.border_width_right = 2
					style.border_width_top = 2
					style.border_width_bottom = 2
					if faction.karma > 20:
						style.border_color = Color.GREEN
					elif faction.karma < -20:
						style.border_color = Color.RED
					else:
						style.border_color = Color.GRAY
					break

		panel.add_theme_stylebox_override("panel", style)

		# 文本
		var display_name = r["name"]
		if region_id == "player_home":
			display_name = "★" + display_name
		elif not r["special_locations"].is_empty():
			var has_dungeon = false
			for loc in r["special_locations"]:
				if loc in DataRegistry.dungeon_templates:
					has_dungeon = true
					break
			if has_dungeon:
				display_name += " 秘"

		name_label.text = display_name
		terrain_label.text = DataRegistry.get_terrain_icon(r["terrain"])


func _refresh_detail(region_id: String) -> void:
	var r = DataRegistry.map_regions.get(region_id, {})
	if r.is_empty():
		return

	var controller = WorldController.get_region_controller(region_id)
	var controller_text = controller if controller != "" else "无主之地"
	if controller == "本门":
		controller_text = "[color=#E6D633]★ 本门[/color]"

	var terrain_names = {"plain": "平原", "mountain": "山地", "forest": "森林",
		"desert": "沙漠", "river": "水域", "swamp": "沼泽", "volcano": "火山"}

	_detail_title.text = r["name"]
	_detail_info.clear()
	_detail_info.append_text("[b]%s[/b]\n\n" % r["name"])
	_detail_info.append_text("地形: %s %s\n" % [terrain_names.get(r["terrain"], "未知"), DataRegistry.get_terrain_icon(r["terrain"])])
	_detail_info.append_text("灵气: [color=#88BBFF]%d[/color]\n" % r["spiritual_density"])
	_detail_info.append_text("危险: [color=#FF8888]%d[/color]\n" % r["danger_level"])
	_detail_info.append_text("控制者: %s\n\n" % controller_text)

	# 该区域的NPC宗门信息
	for faction in WorldController.npc_factions:
		if faction.home_region == region_id and faction.is_alive:
			var karma_text = "正" if faction.karma > 20 else ("魔" if faction.karma < -20 else "中")
			_detail_info.append_text("[b]%s[/b] [%s] | %s\n" % [
				faction.faction_name,
				karma_text,
				DataRegistry.get_realm_name(faction.faction_realm),
			])
			_detail_info.append_text("  弟子: %d | 战力: %d | 关系: %d\n" % [
				faction.disciples.size(),
				faction.combat_power,
				faction.relation_to_player,
			])

	_detail_info.append_text("\n%s\n\n" % r["description"])

	if not r["special_locations"].is_empty():
		_detail_info.append_text("[b]特殊地点:[/b]\n")
		for loc in r["special_locations"]:
			var dungeon = DataRegistry.dungeon_templates.get(loc, {})
			if not dungeon.is_empty():
				var dname = dungeon.get("dungeon_name", loc)
				var diff = dungeon.get("difficulty", 1)
				var stars = ""
				for _i in range(diff): stars += "★"
				_detail_info.append_text("· %s [%s]\n" % [dname, stars])


func _on_year_passed(_year: int) -> void:
	_refresh()
	_add_world_log_entry("宗门历%d年 — 天下势力格局悄然变化……" % _year)


func _add_world_log_entry(text: String) -> void:
	_world_log.append_text(text + "\n")
