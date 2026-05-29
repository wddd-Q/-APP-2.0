extends Node
## 修真主题管理器 — 全局UI配色/字体/样式统一

# 配色方案：修真古卷风
const COLOR_BG = Color(0.08, 0.06, 0.04, 1.0)         # 墨黑底
const COLOR_PANEL = Color(0.14, 0.11, 0.07, 1.0)       # 深棕面板
const COLOR_PANEL_LIGHT = Color(0.18, 0.14, 0.09, 1.0) # 浅棕面板
const COLOR_GOLD = Color(0.9, 0.78, 0.25, 1.0)         # 金色强调
const COLOR_GOLD_DARK = Color(0.55, 0.45, 0.15, 1.0)   # 暗金边框
const COLOR_TEXT = Color(0.94, 0.91, 0.82, 1.0)        # 暖白文字
const COLOR_TEXT_DIM = Color(0.6, 0.55, 0.45, 1.0)     # 暗文字
const COLOR_JADE = Color(0.25, 0.65, 0.35, 1.0)        # 玉绿（正面）
const COLOR_CRIMSON = Color(0.75, 0.2, 0.15, 1.0)      # 赤红（负面）
const COLOR_BLUE = Color(0.3, 0.5, 0.8, 1.0)           # 水蓝（灵气）
const COLOR_OVERLAY = Color(0, 0, 0, 0.65)             # 遮罩

var _theme: Theme


func _ready() -> void:
	_create_theme()
	# 延迟一帧应用，确保UI树已构建
	call_deferred("apply_theme")


func _create_theme() -> void:
	_theme = Theme.new()

	# === 全局默认字体 ===
	_theme.set_default_font_size(16)

	# === Button ===
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.2, 0.15, 0.1, 1.0)
	btn_normal.border_width_left = 1
	btn_normal.border_width_right = 1
	btn_normal.border_width_top = 1
	btn_normal.border_width_bottom = 1
	btn_normal.border_color = COLOR_GOLD_DARK
	btn_normal.corner_radius_top_left = 4
	btn_normal.corner_radius_top_right = 4
	btn_normal.corner_radius_bottom_left = 4
	btn_normal.corner_radius_bottom_right = 4
	btn_normal.content_margin_left = 12
	btn_normal.content_margin_right = 12
	btn_normal.content_margin_top = 6
	btn_normal.content_margin_bottom = 6
	_theme.set_stylebox("normal", "Button", btn_normal)

	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color(0.3, 0.22, 0.13, 1.0)
	btn_hover.border_color = COLOR_GOLD
	_theme.set_stylebox("hover", "Button", btn_hover)

	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = Color(0.15, 0.1, 0.06, 1.0)
	_theme.set_stylebox("pressed", "Button", btn_pressed)

	var btn_disabled = btn_normal.duplicate()
	btn_disabled.bg_color = Color(0.12, 0.1, 0.08, 0.6)
	btn_disabled.border_color = Color(0.3, 0.3, 0.3, 0.5)
	_theme.set_stylebox("disabled", "Button", btn_disabled)

	_theme.set_color("font_color", "Button", COLOR_GOLD)
	_theme.set_color("font_hover_color", "Button", Color.WHITE)
	_theme.set_color("font_pressed_color", "Button", COLOR_GOLD.lightened(0.2))
	_theme.set_color("font_disabled_color", "Button", Color(0.4, 0.4, 0.4, 1.0))

	# === Panel ===
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = COLOR_GOLD_DARK
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	_theme.set_stylebox("panel", "Panel", panel_style)

	# === Label ===
	_theme.set_color("font_color", "Label", COLOR_TEXT)
	_theme.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.3))

	# === RichTextLabel ===
	_theme.set_color("default_color", "RichTextLabel", COLOR_TEXT)
	_theme.set_color("font_outline_color", "RichTextLabel", Color(0, 0, 0, 0.3))

	# === TabContainer ===
	var tab_panel = StyleBoxFlat.new()
	tab_panel.bg_color = COLOR_PANEL
	tab_panel.border_width_left = 1
	tab_panel.border_width_right = 1
	tab_panel.border_width_bottom = 1
	tab_panel.border_color = COLOR_GOLD_DARK
	_theme.set_stylebox("panel", "TabContainer", tab_panel)

	var tab_bar = StyleBoxFlat.new()
	tab_bar.bg_color = Color(0.1, 0.08, 0.05, 1.0)
	tab_bar.border_width_bottom = 2
	tab_bar.border_color = COLOR_GOLD_DARK
	_theme.set_stylebox("tab_bar", "TabContainer", tab_bar)

	var tab_normal = StyleBoxFlat.new()
	tab_normal.bg_color = Color(0.15, 0.12, 0.08, 1.0)
	tab_normal.border_width_top = 1
	tab_normal.border_width_left = 1
	tab_normal.border_width_right = 1
	tab_normal.border_color = COLOR_GOLD_DARK
	tab_normal.corner_radius_top_left = 4
	tab_normal.corner_radius_top_right = 4
	tab_normal.content_margin_left = 8
	tab_normal.content_margin_right = 8
	tab_normal.content_margin_top = 4
	tab_normal.content_margin_bottom = 4
	_theme.set_stylebox("tab_selected", "TabContainer", tab_normal)
	_theme.set_stylebox("tab_unselected", "TabContainer", tab_normal)

	# === OptionButton ===
	var opt_normal = StyleBoxFlat.new()
	opt_normal.bg_color = Color(0.18, 0.13, 0.08, 1.0)
	opt_normal.border_width_left = 1
	opt_normal.border_width_right = 1
	opt_normal.border_width_top = 1
	opt_normal.border_width_bottom = 1
	opt_normal.border_color = COLOR_GOLD_DARK
	opt_normal.corner_radius_top_left = 4
	opt_normal.corner_radius_top_right = 4
	opt_normal.corner_radius_bottom_left = 4
	opt_normal.corner_radius_bottom_right = 4
	opt_normal.content_margin_left = 8
	opt_normal.content_margin_right = 8
	_theme.set_stylebox("normal", "OptionButton", opt_normal)

	var opt_hover = opt_normal.duplicate()
	opt_hover.border_color = COLOR_GOLD
	_theme.set_stylebox("hover", "OptionButton", opt_hover)

	_theme.set_color("font_color", "OptionButton", COLOR_TEXT)

	# === ScrollBar ===
	var v_scroll = StyleBoxFlat.new()
	v_scroll.bg_color = Color(0.15, 0.12, 0.08, 0.8)
	v_scroll.corner_radius_top_left = 3
	v_scroll.corner_radius_top_right = 3
	v_scroll.corner_radius_bottom_left = 3
	v_scroll.corner_radius_bottom_right = 3
	_theme.set_stylebox("scroll", "VScrollBar", v_scroll)

	var grab = StyleBoxFlat.new()
	grab.bg_color = COLOR_GOLD_DARK
	grab.corner_radius_top_left = 3
	grab.corner_radius_top_right = 3
	grab.corner_radius_bottom_left = 3
	grab.corner_radius_bottom_right = 3
	_theme.set_stylebox("grab", "VScrollBar", grab)
	_theme.set_stylebox("grab", "HScrollBar", grab)

	# === HSeparator ===
	var sep = StyleBoxLine.new()
	sep.color = COLOR_GOLD_DARK
	sep.thickness = 1
	_theme.set_stylebox("separator", "HSeparator", sep)
	_theme.set_stylebox("separator", "VSeparator", sep)

	# === ProgressBar ===
	var prog_bg = StyleBoxFlat.new()
	prog_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	_theme.set_stylebox("background", "ProgressBar", prog_bg)

	var prog_fill = StyleBoxFlat.new()
	prog_fill.bg_color = COLOR_JADE
	prog_fill.corner_radius_top_left = 3
	prog_fill.corner_radius_top_right = 3
	prog_fill.corner_radius_bottom_left = 3
	prog_fill.corner_radius_bottom_right = 3
	_theme.set_stylebox("fill", "ProgressBar", prog_fill)

	# === 自定义类型样式 ===
	# 主标题
	_theme.set_color("font_color", "HeaderLabel", COLOR_GOLD)
	# 信息文字
	_theme.set_color("font_color", "InfoLabel", COLOR_TEXT_DIM)
	# 强调文字
	_theme.set_color("font_color", "AccentLabel", COLOR_GOLD)


## 创建预定义的 StyleBox 供代码直接使用
func panel_style(has_border: bool = true) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = COLOR_PANEL
	if has_border:
		s.border_width_left = 2
		s.border_width_right = 2
		s.border_width_top = 2
		s.border_width_bottom = 2
		s.border_color = COLOR_GOLD_DARK
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


func section_header_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.16, 0.12, 0.07, 0.8)
	s.border_width_bottom = 1
	s.border_color = COLOR_GOLD.darkened(0.5)
	s.content_margin_left = 4
	s.content_margin_right = 4
	s.content_margin_top = 2
	s.content_margin_bottom = 4
	return s


func gold_button_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.25, 0.18, 0.08, 1.0)
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = COLOR_GOLD
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


func danger_button_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.25, 0.1, 0.08, 1.0)
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.border_color = COLOR_CRIMSON
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


## 将主题应用到所有UI
func apply_theme() -> void:
	var root = get_tree().root
	if root:
		root.theme = _theme
		# 设置背景色
		if root is Window:
			RenderingServer.set_default_clear_color(COLOR_BG)

	# 生成程序化背景纹理
	call_deferred("_apply_background")


func _apply_background() -> void:
	var tree = get_tree()
	if not tree:
		return
	var root = tree.root
	# 查找主场景的 Background
	var main = root.get_child(0) if root.get_child_count() > 0 else null
	if not main or not main.has_node("Background"):
		return

	var bg_node: Node = main.get_node("Background")
	if not bg_node:
		return

	# 创建渐变纹理 — 从上到下的墨色渐变
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.05, 0.03, 0.02, 1.0))    # 顶部深墨
	gradient.add_point(0.3, Color(0.1, 0.07, 0.04, 1.0))      # 中上微亮
	gradient.add_point(0.6, Color(0.12, 0.08, 0.05, 1.0))     # 中段
	gradient.add_point(1.0, Color(0.06, 0.04, 0.03, 1.0))     # 底部暗

	var gradient_tex = GradientTexture2D.new()
	gradient_tex.gradient = gradient
	gradient_tex.width = 256
	gradient_tex.height = 256
	gradient_tex.fill = GradientTexture2D.FILL_LINEAR

	_set_background_texture(bg_node, gradient_tex)

func _set_background_texture(bg_node: Node, bg_tex: Texture2D) -> void:
	if not bg_node or not bg_tex:
		return

	if bg_node is Control:
		var bg_control := bg_node as Control
		bg_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if bg_node is TextureRect:
		var texture_rect := bg_node as TextureRect
		texture_rect.texture = bg_tex
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		texture_rect.modulate = Color.WHITE
		return

	if bg_node is ColorRect:
		var color_rect := bg_node as ColorRect
		color_rect.color = Color.WHITE
		var art_rect := color_rect.get_node_or_null("ArtTexture") as TextureRect
		if not art_rect:
			art_rect = TextureRect.new()
			art_rect.name = "ArtTexture"
			art_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			color_rect.add_child(art_rect)
			color_rect.move_child(art_rect, 0)
		art_rect.texture = bg_tex
		art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art_rect.modulate = Color.WHITE



## 使用程序化纹理（升级版主题）
func apply_theme_with_textures() -> void:
	var tg = get_node_or_null("/root/TextureGenerator")
	if not tg:
		apply_theme()
		return

	_theme = Theme.new()
	_theme.set_default_font_size(16)

	# === Button ===
	var btn_tex = tg.get_texture("btn_normal")
	if btn_tex:
		var btn_normal = StyleBoxTexture.new()
		btn_normal.texture = btn_tex
		btn_normal.texture_margin_left = 56
		btn_normal.texture_margin_right = 56
		btn_normal.texture_margin_top = 24
		btn_normal.texture_margin_bottom = 24
		btn_normal.modulate_color = Color.WHITE
		_theme.set_stylebox("normal", "Button", btn_normal)

	var btn_hover_tex = tg.get_texture("btn_hover")
	if btn_hover_tex:
		var btn_hover = StyleBoxTexture.new()
		btn_hover.texture = btn_hover_tex
		btn_hover.texture_margin_left = 56
		btn_hover.texture_margin_right = 56
		btn_hover.texture_margin_top = 24
		btn_hover.texture_margin_bottom = 24
		_theme.set_stylebox("hover", "Button", btn_hover)

	var btn_pressed_tex = tg.get_texture("btn_pressed")
	if btn_pressed_tex:
		var btn_pressed = StyleBoxTexture.new()
		btn_pressed.texture = btn_pressed_tex
		btn_pressed.texture_margin_left = 56
		btn_pressed.texture_margin_right = 56
		btn_pressed.texture_margin_top = 24
		btn_pressed.texture_margin_bottom = 24
		_theme.set_stylebox("pressed", "Button", btn_pressed)

	_theme.set_color("font_color", "Button", COLOR_GOLD)
	_theme.set_color("font_hover_color", "Button", Color.WHITE)

	# === Panel — 羊皮纸纹理 ===
	var panel_tex = tg.get_texture("panel_bg")
	if panel_tex:
		var panel_style = StyleBoxTexture.new()
		panel_style.texture = panel_tex
		panel_style.texture_margin_left = 64
		panel_style.texture_margin_right = 64
		panel_style.texture_margin_top = 64
		panel_style.texture_margin_bottom = 64
		# 画金边
		var border_tex = tg.get_texture("border_gold")
		if border_tex:
			# 使用 modulate 给边框着色
			panel_style.modulate_color = Color(0.85, 0.75, 0.5, 1.0)
		_theme.set_stylebox("panel", "Panel", panel_style)

	# === Label ===
	_theme.set_color("font_color", "Label", COLOR_TEXT)
	_theme.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.3))
	_theme.set_color("default_color", "RichTextLabel", COLOR_TEXT)

	# === TabContainer ===
	var tab_tex = tg.get_texture("tab_selected")
	if tab_tex:
		var tab_style = StyleBoxTexture.new()
		tab_style.texture = tab_tex
		tab_style.texture_margin_left = 36
		tab_style.texture_margin_right = 36
		tab_style.texture_margin_top = 18
		tab_style.texture_margin_bottom = 18
		_theme.set_stylebox("tab_selected", "TabContainer", tab_style)
		_theme.set_stylebox("tab_unselected", "TabContainer", tab_style)

	# === OptionButton ===
	var opt_tex = tg.get_texture("btn_normal")
	if opt_tex:
		var opt_style = StyleBoxTexture.new()
		opt_style.texture = opt_tex
		opt_style.texture_margin_left = 48
		opt_style.texture_margin_right = 48
		opt_style.texture_margin_top = 22
		opt_style.texture_margin_bottom = 22
		_theme.set_stylebox("normal", "OptionButton", opt_style)
	_theme.set_color("font_color", "OptionButton", COLOR_TEXT)

	# === ScrollBar ===
	var scroll_style = StyleBoxFlat.new()
	scroll_style.bg_color = Color(0.15, 0.12, 0.08, 0.6)
	scroll_style.corner_radius_top_left = 3
	scroll_style.corner_radius_top_right = 3
	scroll_style.corner_radius_bottom_left = 3
	scroll_style.corner_radius_bottom_right = 3
	_theme.set_stylebox("scroll", "VScrollBar", scroll_style)

	var grab_style = StyleBoxFlat.new()
	grab_style.bg_color = COLOR_GOLD_DARK
	grab_style.corner_radius_top_left = 3
	grab_style.corner_radius_top_right = 3
	grab_style.corner_radius_bottom_left = 3
	grab_style.corner_radius_bottom_right = 3
	_theme.set_stylebox("grab", "VScrollBar", grab_style)
	_theme.set_stylebox("grab", "HScrollBar", grab_style)

	# 应用到根节点
	var root = get_tree().root
	if root:
		root.theme = _theme

	# 更新背景
	_apply_textured_background(tg)


func _apply_textured_background(tg: Node) -> void:
	var tree = get_tree()
	if not tree:
		return
	var main = tree.root.get_child(0) if tree.root.get_child_count() > 0 else null
	if not main or not main.has_node("Background"):
		return
	var bg_node: Node = main.get_node("Background")
	if not bg_node:
		return

	var bg_tex = tg.get_texture("bg_main")
	if bg_tex:
		_set_background_texture(bg_node, bg_tex)
