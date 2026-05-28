extends Node
## 程序化纹理生成器 — 生成修真风UI纹理占位图
## AI生成素材后直接替换 assets/textures/ui/ 下对应文件即可
## 优先加载外部PNG，未找到则回退程序化生成


var _texture_cache: Dictionary = {}

# 纹理名 → 文件路径映射
const TEXTURE_PATHS: Dictionary = {
	"panel_bg": "res://assets/textures/ui/panels/panel_bg.png",
	"panel_header": "res://assets/textures/ui/panels/panel_header.png",
	"btn_normal": "res://assets/textures/ui/buttons/btn_normal.png",
	"btn_hover": "res://assets/textures/ui/buttons/btn_hover.png",
	"btn_pressed": "res://assets/textures/ui/buttons/btn_pressed.png",
	"btn_gold": "res://assets/textures/ui/buttons/btn_gold.png",
	"btn_danger": "res://assets/textures/ui/buttons/btn_danger.png",
	"border_frame": "res://assets/textures/ui/decorations/border_frame.png",
	"divider": "res://assets/textures/ui/decorations/divider.png",
	"cloud_pattern": "res://assets/textures/ui/decorations/cloud_pattern.png",
	"bg_main": "res://assets/textures/bg/bg_main.png",
	"bg_sect": "res://assets/textures/bg/bg_sect.png",
}


func _ready() -> void:
	_generate_all_textures()
	EventBus.game_started.connect(_on_game_started)


func _on_game_started() -> void:
	ThemeManager.apply_theme_with_textures()


## 获取已生成的纹理
func get_texture(name: String) -> Texture2D:
	if _texture_cache.has(name):
		return _texture_cache[name]
	return null


## 尝试加载外部PNG，失败则调用生成函数
func _load_or_generate(name: String, generate_fn: Callable) -> Texture2D:
	var path = TEXTURE_PATHS.get(name, "")
	if not path.is_empty() and ResourceLoader.exists(path):
		var img = Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			print("[TextureGenerator] 加载外部纹理: %s" % path)
			return ImageTexture.create_from_image(img)

	print("[TextureGenerator] 使用程序化纹理: %s" % name)
	return generate_fn.call()


func _generate_all_textures() -> void:
	# === 面板纹理 ===
	_texture_cache["panel_bg"] = _load_or_generate("panel_bg", func(): return _make_parchment(256, 256, Color(0.18, 0.14, 0.09, 1.0), 0.04))
	_texture_cache["panel_header"] = _load_or_generate("panel_header", func(): return _make_parchment(256, 32, Color(0.22, 0.16, 0.1, 1.0), 0.03))

	# === 按钮纹理 ===
	_texture_cache["btn_normal"] = _load_or_generate("btn_normal", func(): return _make_button(200, 44, Color(0.25, 0.18, 0.1, 1.0)))
	_texture_cache["btn_hover"] = _load_or_generate("btn_hover", func(): return _make_button(200, 44, Color(0.35, 0.25, 0.13, 1.0)))
	_texture_cache["btn_pressed"] = _load_or_generate("btn_pressed", func(): return _make_button(200, 44, Color(0.15, 0.1, 0.06, 1.0)))
	_texture_cache["btn_gold"] = _load_or_generate("btn_gold", func(): return _make_button(200, 44, Color(0.28, 0.2, 0.08, 1.0)))
	_texture_cache["btn_danger"] = _load_or_generate("btn_danger", func(): return _make_button(200, 44, Color(0.3, 0.1, 0.08, 1.0)))

	# === Tab 纹理 ===
	_texture_cache["tab_normal"] = _load_or_generate("tab_normal", func(): return _make_parchment(100, 32, Color(0.2, 0.15, 0.09, 1.0), 0.03))
	_texture_cache["tab_selected"] = _load_or_generate("tab_selected", func(): return _make_parchment(100, 32, Color(0.25, 0.18, 0.1, 1.0), 0.02))

	# === 边框 ===
	_texture_cache["border_gold"] = _load_or_generate("border_gold", func(): return _make_border(8, Color(0.55, 0.45, 0.15, 1.0)))

	# === 装饰 ===
	_texture_cache["border_frame"] = _load_or_generate("border_frame", func():
		var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		return ImageTexture.create_from_image(img)
	)
	_texture_cache["divider"] = _load_or_generate("divider", func():
		var img = Image.create(256, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.55, 0.45, 0.15, 0.6))
		return ImageTexture.create_from_image(img)
	)
	_texture_cache["cloud_pattern"] = _load_or_generate("cloud_pattern", func():
		var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		return ImageTexture.create_from_image(img)
	)

	# === 背景 ===
	_texture_cache["bg_main"] = _load_or_generate("bg_main", func():
		var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
		_add_noise_gradient(img, Color(0.06, 0.04, 0.03, 1.0), Color(0.12, 0.08, 0.05, 1.0), 0.06, true)
		return ImageTexture.create_from_image(img)
	)
	_texture_cache["bg_sect"] = _load_or_generate("bg_sect", func():
		var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
		_add_noise_gradient(img, Color(0.15, 0.25, 0.08, 1.0), Color(0.18, 0.15, 0.06, 1.0), 0.05, false)
		return ImageTexture.create_from_image(img)
	)

	print("[TextureGenerator] 已生成 %d 个纹理 (外部:%d 程序化:%d)" % [
		_texture_cache.size(),
		_count_external(),
		_texture_cache.size() - _count_external(),
	])


func _count_external() -> int:
	var count = 0
	for name in TEXTURE_PATHS:
		if ResourceLoader.exists(TEXTURE_PATHS[name]):
			count += 1
	return count


## 仿羊皮纸纹理
func _make_parchment(w: int, h: int, base: Color, noise_amount: float) -> Texture2D:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	_add_noise_gradient(img, base.darkened(0.1), base.lightened(0.08), noise_amount, false)
	return ImageTexture.create_from_image(img)


## 按钮纹理（带渐变）
func _make_button(w: int, h: int, base: Color) -> Texture2D:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var t = float(y) / h
		var col = base.lerp(base.lightened(0.12), 1.0 - t)
		for x in range(w):
			img.set_pixel(x, y, col)

	# 顶部高光线
	var hilight = base.lightened(0.25)
	for x in range(4, w - 4):
		img.set_pixel(x, 1, hilight)
		img.set_pixel(x, 2, hilight)

	# 底部阴影线
	var shadow = base.darkened(0.15)
	for x in range(4, w - 4):
		img.set_pixel(x, h - 2, shadow)

	return ImageTexture.create_from_image(img)


## 装饰边框
func _make_border(thickness: int, color: Color) -> Texture2D:
	var size = thickness * 2
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	for i in range(thickness):
		var alpha = 1.0 - (float(i) / thickness) * 0.3
		var col = Color(color.r, color.g, color.b, color.a * alpha)
		img.set_pixel(i, i, col)
		img.set_pixel(size - 1 - i, i, col)
		img.set_pixel(i, size - 1 - i, col)
		img.set_pixel(size - 1 - i, size - 1 - i, col)
	return ImageTexture.create_from_image(img)


## 噪声渐变填充
func _add_noise_gradient(img: Image, top_color: Color, bottom_color: Color, noise_strength: float, vertical: bool) -> void:
	var w = img.get_width()
	var h = img.get_height()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("xiuxian_ui")

	for y in range(h):
		var t = float(y) / h
		var base_col = top_color.lerp(bottom_color, t)
		for x in range(w):
			var noise = (rng.randf() - 0.5) * noise_strength * 2.0
			var final = Color(
				clampf(base_col.r + noise, 0.0, 1.0),
				clampf(base_col.g + noise, 0.0, 1.0),
				clampf(base_col.b + noise, 0.0, 1.0),
				base_col.a
			)
			img.set_pixel(x, y, final)
