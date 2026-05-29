class_name DisciplePortrait
extends Control
## 弟子头像 — 三层回退：精确匹配 → 头像池 → 程序化绘制
## 精确匹配：assets/textures/portraits/{弟子名}.png
## 头像池：  assets/textures/portraits/pool_01~XX.png（自动分配）


const PORTRAIT_DIR := "res://assets/textures/portraits/"

const ROOT_COLORS: Dictionary = {
	"heaven": Color(0.95, 0.78, 0.15, 1.0),
	"variant": Color(0.65, 0.35, 0.85, 1.0),
	"true": Color(0.25, 0.55, 0.85, 1.0),
	"false": Color(0.35, 0.70, 0.35, 1.0),
	"waste": Color(0.55, 0.55, 0.55, 1.0),
}

const ELEMENT_COLORS: Dictionary = {
	0: Color(0.95, 0.85, 0.3, 1.0),
	1: Color(0.25, 0.75, 0.30, 1.0),
	2: Color(0.25, 0.50, 0.90, 1.0),
	3: Color(0.90, 0.25, 0.20, 1.0),
	4: Color(0.75, 0.55, 0.20, 1.0),
}


var _disciple: DiscipleData
var _avatar_size: int
var _custom_texture: Texture2D = null
var _texture_loaded: bool = false

# 头像池缓存（类级别共享）
static var _pool_cache: Array[String] = []
static var _pool_scanned: bool = false


func setup(disciple: DiscipleData, size: int = 64) -> void:
	_disciple = disciple
	_avatar_size = size
	custom_minimum_size = Vector2(size, size)
	_try_load_custom_texture()
	queue_redraw()


func _try_load_custom_texture() -> void:
	if _texture_loaded:
		return
	_texture_loaded = true

	if not _disciple or _disciple.disciple_name.is_empty():
		return

	# 第一层：精确匹配 {名字}.png
	var exact_path = PORTRAIT_DIR + _disciple.disciple_name + ".png"
	if FileAccess.file_exists(ProjectSettings.globalize_path(exact_path)):
		_custom_texture = _load_texture(exact_path)
		if _custom_texture:
			return

	# 第二层：从头像池中分配
	var pool_path = _get_pool_texture()
	if pool_path != "":
		_custom_texture = _load_texture(pool_path)


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded

	var img = Image.load_from_file(ProjectSettings.globalize_path(path))
	if img != null:
		return ImageTexture.create_from_image(img)
	return null


func _get_pool_texture() -> String:
	_scan_pool()
	if _pool_cache.is_empty():
		return ""

	# 用弟子名的 hash 稳定分配（同一弟子每次获得同一张图）
	var hash_val = hash(_disciple.disciple_name)
	var idx = abs(hash_val) % _pool_cache.size()
	return _pool_cache[idx]


static func _scan_pool() -> void:
	if _pool_scanned:
		return
	_pool_scanned = true
	_pool_cache.clear()

	var i = 1
	while true:
		var path = PORTRAIT_DIR + "pool_%02d.png" % i
		if FileAccess.file_exists(ProjectSettings.globalize_path(path)):
			_pool_cache.append(path)
			i += 1
		else:
			break


func _draw() -> void:
	if not _disciple:
		return

	var center = Vector2(_avatar_size / 2.0, _avatar_size / 2.0)
	var radius = _avatar_size / 2.0 - 2

	if _custom_texture:
		# 自定义图片 + 外圈边框
		var tex_rect = Rect2(center - Vector2(radius, radius), Vector2(radius * 2, radius * 2))
		draw_texture_rect(_custom_texture, tex_rect, false)
		draw_arc(center, radius, 0, TAU, 32, Color(0.55, 0.45, 0.15, 0.8), 2.0, true)
	else:
		_draw_procedural(center, radius)


func _draw_procedural(center: Vector2, radius: float) -> void:
	var bg_color = ROOT_COLORS.get(_disciple.spirit_root_quality, Color(0.4, 0.4, 0.4, 1.0))
	draw_circle(center, radius, bg_color)

	if not _disciple.spirit_elements.is_empty():
		var elem_color = ELEMENT_COLORS.get(_disciple.spirit_elements[0], Color.WHITE)
		draw_arc(center, radius - 1, 0, TAU, 32, elem_color, 3.0, true)
		if _disciple.spirit_elements.size() > 1:
			var arc_angle = TAU / _disciple.spirit_elements.size()
			for i in range(_disciple.spirit_elements.size()):
				var ec = ELEMENT_COLORS.get(_disciple.spirit_elements[i], Color.WHITE)
				draw_arc(center, radius - 1, i * arc_angle, (i + 1) * arc_angle, 32, ec, 3.0, true)

	var char_text = _disciple.disciple_name.substr(0, 1)
	var font_size = _avatar_size / 2
	draw_string(ThemeDB.fallback_font,
		center - Vector2(font_size * 0.65, font_size * 0.65) + Vector2(0, font_size * 0.3),
		char_text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, font_size,
		Color.BLACK
	)

	if _disciple.realm >= 4:
		draw_circle(center, radius + 2, Color(1.0, 0.85, 0.3, 0.4), false, 2.0)
	if _disciple.realm >= 6:
		draw_circle(center, radius + 4, Color(1.0, 0.4, 0.8, 0.5), false, 2.0)
