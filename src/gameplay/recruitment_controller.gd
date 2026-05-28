extends Node
## 招募控制器

const DiscipleData = preload("res://src/core/data/disciple_data.gd")
const NameGenerator = preload("res://src/core/systems/name_generator.gd")


func generate_candidates(count: int = 5) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []

	for i in range(count):
		var gender = randi() % 2
		var name = NameGenerator.generate_name(gender)

		# 随机五行属性
		var elements = _roll_elements()
		var quality = _determine_quality(elements)

		# 属性生成
		var base_points = 200 + randi() % 61  # 200-260
		if quality == "heaven": base_points += 40
		elif quality == "variant": base_points += 20
		elif quality == "waste": base_points -= 20
		# 迎客居加成
		var sect = GameManager.current_sect
		if sect:
			var guest = sect.get_facility("guest_quarters")
			if guest:
				base_points += DataRegistry.facility_templates.get("guest_quarters", {}).get("recruit_quality_bonus", {}).get(guest.level, 0)

		var attrs = _distribute_points(base_points)
		var personalities = _roll_personalities()

		candidates.append({
			"name": name,
			"gender": gender,
			"age": 14 + randi() % 12,
			"bone_structure": attrs[0],
			"comprehension": attrs[1],
			"fortune": attrs[2],
			"mentality": attrs[3],
			"charm": attrs[4],
			"talent": attrs[5],
			"root_quality": quality,
			"root_name": _get_root_display_name(quality),
			"elements": elements,
			"root_revealed": false,  # 灵根是否已检测
			"personalities": personalities,
			"recruit_cost": 50 + randi() % 100,
		})

	return candidates


func detect_spirit_root(candidate: Dictionary) -> void:
	"""消耗灵石检测灵根（玩家支付后调用）"""
	candidate["root_revealed"] = true


func recruit(candidate: Dictionary) -> DiscipleData:
	"""招收弟子，返回 DiscipleData"""
	var sect = GameManager.current_sect
	if not sect:
		return null

	var cost = candidate.get("recruit_cost", 50)
	if not sect.spend_spirit_stones(cost):
		return null

	var d = DiscipleData.new()
	d.disciple_name = candidate["name"]
	d.gender = candidate["gender"]
	d.age = candidate["age"]
	d.bone_structure = candidate["bone_structure"]
	d.comprehension = candidate["comprehension"]
	d.fortune = candidate["fortune"]
	d.mentality = candidate["mentality"]
	d.charm = candidate["charm"]
	d.talent = candidate["talent"]
	d.spirit_root_quality = candidate["root_quality"]
	d.spirit_elements = candidate["elements"]
	d.personalities = candidate.get("personalities", [])
	d.realm = 1
	d.sub_realm = 1
	d.cultivation_progress = 0.0
	d.lifespan = 120  # 练气期
	d.assigned_task = "idle"

	sect.disciples.append(d)
	EventBus.disciple_recruited.emit(d.resource_path)
	EventBus.spirit_stones_changed.emit(sect.spirit_stones, -cost)
	return d


func _roll_elements() -> Array:
	var count = 1 + randi() % 5  # 1-5个属性
	var all = [0, 1, 2, 3, 4]  # 金木水火土
	all.shuffle()
	return all.slice(0, count)


func _determine_quality(elements: Array) -> String:
	var count = elements.size()
	# 检查相生
	var generating_pairs = [[0, 2], [2, 1], [1, 3], [3, 4], [4, 0]]
	var generates = 0
	for i in range(elements.size()):
		for j in range(i + 1, elements.size()):
			if [elements[i], elements[j]] in generating_pairs:
				generates += 1

	# 品质判定
	if count == 1:
		return "heaven"  # 天灵根 0.5%
	elif count == 2:
		return "variant" if generates >= 1 else "true"
	elif count == 3:
		return "true"  # 真灵根 20%
	elif count == 4:
		return "false"  # 伪灵根 45%
	else:
		return "waste"  # 废灵根 29.5%


func _distribute_points(total: int) -> Array:
	var points = [50, 50, 50, 50, 50, 50]  # 起步50
	var remaining = total - 300
	if remaining <= 0:
		return points

	for i in range(remaining):
		var idx = randi() % 6
		if points[idx] < 90:
			points[idx] += 1
	return points


func _roll_personalities() -> Array:
	var pool = ["勇猛", "谨慎", "贪婪", "忠诚", "孤傲", "好奇", "善良", "阴狠", "豪爽", "内敛"]
	pool.shuffle()
	return pool.slice(0, 1 + randi() % 2)  # 1-2个人格标签


func _get_root_display_name(quality: String) -> String:
	var names = {
		"heaven": "天灵根", "variant": "异灵根",
		"true": "真灵根", "false": "伪灵根", "waste": "废灵根",
	}
	return "未知灵根" if quality.is_empty() else names.get(quality, "未知")
