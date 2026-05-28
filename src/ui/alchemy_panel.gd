class_name AlchemyPanel
extends Control
## 炼丹炼器面板


var _recipe_list: VBoxContainer
var _disciple_selector: OptionButton
var _result_label: Label
var _mode: String = "pill"  # "pill" or "craft"
var _disciple_cache: Array = []


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
	panel.size = Vector2(660, 560)
	panel.position = Vector2(get_viewport().get_visible_rect().size / 2 - panel.size / 2)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# 标题
	var title = Label.new()
	title.text = "炼丹炼器"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	# 模式切换
	var mode_row = HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 10)
	mode_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(mode_row)

	var pill_btn = Button.new()
	pill_btn.text = "炼丹"
	pill_btn.pressed.connect(func(): _switch_mode("pill"))
	mode_row.add_child(pill_btn)

	var craft_btn = Button.new()
	craft_btn.text = "炼器"
	craft_btn.pressed.connect(func(): _switch_mode("craft"))
	mode_row.add_child(craft_btn)

	# 弟子选择
	var sel_row = HBoxContainer.new()
	sel_row.add_theme_constant_override("separation", 10)
	vbox.add_child(sel_row)

	var sel_label = Label.new()
	sel_label.text = "炼制者:"
	sel_label.add_theme_font_size_override("font_size", 18)
	sel_row.add_child(sel_label)

	_disciple_selector = OptionButton.new()
	_disciple_selector.add_theme_font_size_override("font_size", 16)
	sel_row.add_child(_disciple_selector)

	# 配方列表
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 300)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_recipe_list = VBoxContainer.new()
	_recipe_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_recipe_list)

	# 结果
	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 16)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_label)

	# 关闭
	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(func(): visible = false)
	vbox.add_child(close_btn)


func open_panel() -> void:
	visible = true
	_switch_mode("pill")


func _switch_mode(mode: String) -> void:
	_mode = mode
	_refresh_disciple_list()
	_refresh_recipe_list()
	_result_label.text = ""


func _refresh_disciple_list() -> void:
	_disciple_selector.clear()
	_disciple_cache.clear()

	var sect = GameManager.current_sect
	if not sect:
		return

	var skill_key = "alchemy" if _mode == "pill" else "crafting"
	for d in sect.disciples:
		if not d.alive:
			continue
		_disciple_cache.append(d)
		var skill_val = d.skills.get(skill_key, 0)
		_disciple_selector.add_item("%s (%s %d)" % [d.disciple_name, "炼丹" if _mode == "pill" else "炼器", skill_val])


func _refresh_recipe_list() -> void:
	for child in _recipe_list.get_children():
		child.queue_free()

	var recipes = DataRegistry.pill_recipes if _mode == "pill" else DataRegistry.craft_recipes
	var sect = GameManager.current_sect
	var material_pool = sect.herbs if _mode == "pill" else sect.ores

	for recipe_id in recipes:
		var r = recipes[recipe_id]
		var card = _make_recipe_card(recipe_id, r, material_pool)
		_recipe_list.add_child(card)


func _make_recipe_card(recipe_id: String, r: Dictionary, material_pool: Dictionary) -> Control:
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)

	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)

	var name_lbl = Label.new()
	name_lbl.text = "%s (难度:%d)" % [r["name"], r["difficulty"]]
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.custom_minimum_size = Vector2(200, 0)
	row1.add_child(name_lbl)

	var materials_str = ""
	var can_afford = true
	for mat_id in r["materials"]:
		var required = r["materials"][mat_id]
		var owned = material_pool.get(mat_id, 0)
		var mat_name = _get_material_name(mat_id)
		materials_str += "%s: %d/%d  " % [mat_name, owned, required]
		if owned < required:
			can_afford = false

	var mat_lbl = Label.new()
	mat_lbl.text = materials_str
	mat_lbl.add_theme_font_size_override("font_size", 14)
	if not can_afford:
		mat_lbl.add_theme_color_override("font_color", Color.RED)
	row1.add_child(mat_lbl)

	card.add_child(row1)

	var craft_btn = Button.new()
	craft_btn.text = "制作 (%d月)" % r.get("craft_time", 1)
	craft_btn.disabled = not can_afford
	var rid = recipe_id
	craft_btn.pressed.connect(func(): _on_craft(rid))
	card.add_child(craft_btn)

	card.add_child(HSeparator.new())
	return card


func _on_craft(recipe_id: String) -> void:
	var idx = _disciple_selector.selected
	if idx < 0 or idx >= _disciple_cache.size():
		_result_label.text = "请选择炼制者"
		return

	var disciple = _disciple_cache[idx]

	if _mode == "pill":
		var recipes = DataRegistry.pill_recipes
		var r = recipes[recipe_id]
		var recipe = PillRecipeData.new()
		recipe.recipe_name = r["name"]
		recipe.result_item = recipe_id
		recipe.materials = r["materials"]
		recipe.base_success_rate = r["base_success_rate"]
		recipe.difficulty = r["difficulty"]
		recipe.craft_time_months = r["craft_time"]

		var result = AlchemyController.craft_pill(recipe, disciple)
		_display_result(result)
	else:
		var recipes = DataRegistry.craft_recipes
		var r = recipes[recipe_id]
		var recipe = CraftRecipeData.new()
		recipe.recipe_name = r["name"]
		recipe.result_item = recipe_id
		recipe.materials = r["materials"]
		recipe.base_success_rate = r["base_success_rate"]
		recipe.difficulty = r["difficulty"]
		recipe.craft_time_months = r["craft_time"]

		var result = AlchemyController.forge_equipment(recipe, disciple)
		_display_result(result)

	_refresh_recipe_list()


func _display_result(result: Dictionary) -> void:
	if result["success"]:
		var quality_name = ""
		match result.get("quality", 1):
			4: quality_name = "【极品!】"
			3: quality_name = "【上品】"
			2: quality_name = "【中品】"
			1: quality_name = "【下品】"
		_result_label.text = "炼制成功! %s %s" % [quality_name, result.get("reason", "")]
		_result_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		_result_label.text = "炼制失败: %s" % result.get("reason", "未知原因")
		_result_label.add_theme_color_override("font_color", Color.RED)


func _get_material_name(mat_id: String) -> String:
	var names = {
		"spirit_herb": "灵草", "ginseng": "人参", "lingzhi": "灵芝",
		"iron": "铁矿石", "silk": "灵蚕丝", "jade": "灵玉",
	}
	return names.get(mat_id, mat_id)
