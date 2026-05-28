class_name DiplomacyPanel
extends Control
## 外交面板 — NPC宗门情报、关系、互动

const DisciplePortrait = preload("res://src/ui/disciple_portrait.gd")

var _faction_list: VBoxContainer
var _detail_label: Label
var _npc_disciples_container: VBoxContainer
var _selected_faction: FactionData = null


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
	panel.size = Vector2(760, 580)
	panel.position = Vector2(get_viewport().get_visible_rect().size / 2 - panel.size / 2)
	add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	# 左侧：势力列表
	var left = VBoxContainer.new()
	left.custom_minimum_size = Vector2(420, 0)
	left.add_theme_constant_override("separation", 10)
	hbox.add_child(left)

	var title = Label.new()
	title.text = "天下势力"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	left.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)

	_faction_list = VBoxContainer.new()
	_faction_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_faction_list)

	# 右侧：详情
	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(290, 0)
	right.add_theme_constant_override("separation", 12)
	hbox.add_child(right)

	var detail_title = Label.new()
	detail_title.text = "宗门声望"
	detail_title.add_theme_font_size_override("font_size", 20)
	right.add_child(detail_title)

	var self_info = Label.new()
	var sect = GameManager.current_sect
	if sect:
		var rank_names = {9:"九品",8:"八品",7:"七品",6:"六品",5:"五品",4:"四品",3:"三品",2:"二品",1:"一品",0:"超品"}
		self_info.text = "%s (%s)\n声望: %d\n灵石: %d\n弟子: %d" % [
			sect.name,
			rank_names.get(sect.rank, "?品"),
			sect.prestige,
			sect.spirit_stones,
			sect.disciples.size(),
		]
	self_info.add_theme_font_size_override("font_size", 16)
	right.add_child(self_info)

	_detail_label = Label.new()
	_detail_label.text = "点击左侧势力查看详情"
	_detail_label.add_theme_font_size_override("font_size", 15)
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	right.add_child(_detail_label)

	# NPC宗门弟子列表
	var npc_disc_title = Label.new()
	npc_disc_title.text = "宗门弟子:"
	npc_disc_title.add_theme_font_size_override("font_size", 16)
	npc_disc_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1.0))
	right.add_child(npc_disc_title)

	var npc_scroll = ScrollContainer.new()
	npc_scroll.custom_minimum_size = Vector2(0, 150)
	npc_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(npc_scroll)

	_npc_disciples_container = VBoxContainer.new()
	_npc_disciples_container.add_theme_constant_override("separation", 4)
	npc_scroll.add_child(_npc_disciples_container)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(func(): visible = false)
	right.add_child(close_btn)


func open_panel() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	for child in _faction_list.get_children():
		child.queue_free()

	var factions = WorldController.npc_factions
	if factions.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无其他势力"
		_faction_list.add_child(lbl)
		return

	for faction in factions:
		if not faction.is_alive:
			continue
		var card = _make_faction_card(faction)
		_faction_list.add_child(card)


func _make_faction_card(faction: FactionData) -> Control:
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)

	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)

	var name_btn = Button.new()
	name_btn.text = faction.faction_name
	name_btn.flat = true
	name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_btn.add_theme_font_size_override("font_size", 18)
	var fac = faction
	name_btn.pressed.connect(func(): _show_faction_detail(fac))
	row1.add_child(name_btn)

	var karma_text = "正道" if faction.karma > 20 else ("魔道" if faction.karma < -20 else "中立")
	var karma_lbl = Label.new()
	karma_lbl.text = "[%s]" % karma_text
	karma_lbl.add_theme_font_size_override("font_size", 14)
	var karma_color = Color.GREEN if faction.karma > 20 else (Color.RED if faction.karma < -20 else Color.GRAY)
	karma_lbl.add_theme_color_override("font_color", karma_color)
	row1.add_child(karma_lbl)

	card.add_child(row1)

	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)

	var realm_name = DataRegistry.get_realm_name(faction.faction_realm)
	var rank_names = {9:"九品",8:"八品",7:"七品",6:"六品",5:"五品",4:"四品",3:"三品",2:"二品",1:"一品",0:"超品"}

	var info_lbl = Label.new()
	info_lbl.text = "%s | %s | 战力:%d | 关系:%d" % [
		rank_names.get(faction.faction_rank, "?品"),
		realm_name,
		faction.combat_power,
		faction.relation_to_player,
	]
	info_lbl.add_theme_font_size_override("font_size", 14)

	if faction.relation_to_player >= 30:
		info_lbl.add_theme_color_override("font_color", Color.GREEN)
	elif faction.relation_to_player <= -30:
		info_lbl.add_theme_color_override("font_color", Color.RED)
	row2.add_child(info_lbl)

	card.add_child(row2)
	card.add_child(HSeparator.new())
	return card


func _show_faction_detail(faction: FactionData) -> void:
	_selected_faction = faction
	var rank_names = {9:"九品",8:"八品",7:"七品",6:"六品",5:"五品",4:"四品",3:"三品",2:"二品",1:"一品",0:"超品"}
	var realm_name = DataRegistry.get_realm_name(faction.faction_realm)
	var karma_text = "正道" if faction.karma > 20 else ("魔道" if faction.karma < -20 else "中立")
	var rel_text = _relation_text(faction.relation_to_player)

	_detail_label.text = """%s
	%s | %s
	阵营: %s
	战力: %d
	关系: %s (%d)
	侵略性: %d
	外交能力: %d""" % [
		faction.faction_name,
		rank_names.get(faction.faction_rank, "?品"),
		realm_name,
		karma_text,
		faction.combat_power,
		rel_text,
		faction.relation_to_player,
		faction.aggression,
		faction.diplomacy,
	]

	_refresh_npc_disciples(faction)


func _refresh_npc_disciples(faction: FactionData) -> void:
	for child in _npc_disciples_container.get_children():
		child.queue_free()

	if faction.disciples.is_empty():
		var lbl = Label.new()
		lbl.text = "  暂无情报"
		lbl.add_theme_color_override("font_color", Color.GRAY)
		_npc_disciples_container.add_child(lbl)
		return

	var sorted = faction.disciples.duplicate()
	sorted.sort_custom(func(a, b): return a["realm"] > b["realm"] or (a["realm"] == b["realm"] and a["sub_realm"] > b["sub_realm"]))

	for disc in sorted:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		# 用 Dictionary 构造临时 DiscipleData 给头像用
		var temp_d = DiscipleData.new()
		temp_d.disciple_name = disc["name"]
		temp_d.spirit_root_quality = disc["spirit_root_quality"]
		temp_d.spirit_elements = disc["spirit_elements"]
		temp_d.realm = disc["realm"]

		var portrait = DisciplePortrait.new()
		portrait.setup(temp_d, 28)
		row.add_child(portrait)

		var realm_name = DataRegistry.get_realm_name(disc["realm"])
		var info = Label.new()
		info.text = "%s | %s%d层 | %s | %d岁" % [
			disc["name"],
			realm_name, disc["sub_realm"],
			disc.get("spirit_root_name", "?灵根"),
			disc["age"],
		]
		info.add_theme_font_size_override("font_size", 13)
		row.add_child(info)

		_npc_disciples_container.add_child(row)


func _relation_text(value: int) -> String:
	if value >= 60: return "同盟"
	if value >= 30: return "友好"
	if value >= 0: return "中立"
	if value >= -30: return "紧张"
	if value >= -60: return "敌对"
	return "死敌"
