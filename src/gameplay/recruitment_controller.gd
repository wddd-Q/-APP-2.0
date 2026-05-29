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
		var archetype = _roll_archetype()
		var base_points = 240 + randi() % 61  # 240-300
		if quality == "heaven": base_points += 40
		elif quality == "variant": base_points += 20
		elif quality == "waste": base_points -= 20
		# 迎客居加成
		var sect = GameManager.current_sect
		if sect:
			var guest = sect.get_facility("guest_quarters")
			if guest:
				base_points += DataRegistry.facility_templates.get("guest_quarters", {}).get("recruit_quality_bonus", {}).get(guest.level, 0)

		var attrs = _distribute_points(base_points, archetype)
		var personalities = _roll_personalities()
		var specialty = archetype["name"]
		var origin_story = _make_origin_story(name, gender, specialty, personalities, quality)

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
			"specialty": specialty,
			"origin_story": origin_story,
			"skill_focus": archetype.get("skill", ""),
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
	d.specialty = candidate.get("specialty", "")
	d.origin_story = candidate.get("origin_story", "")
	d.loyalty = _initial_loyalty(d.personalities)
	var skill_focus = candidate.get("skill_focus", "")
	if skill_focus != "":
		d.skills[skill_focus] = 12 + randi() % 24
	d.realm = 1
	d.sub_realm = 1
	d.cultivation_progress = 0.0
	d.lifespan = 120  # 练气期
	d.assigned_task = "idle"

	sect.add_disciple(d)
	d.add_memory("宗门历%d年 %s通过招徒令拜入宗门。" % [TimeManager.year, d.disciple_name])
	if d.origin_story != "":
		d.add_memory("入门来历：%s" % d.origin_story)
	EventBus.disciple_recruited.emit(d.disciple_id)
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


func _distribute_points(total: int, archetype: Dictionary) -> Array:
	var points = [25, 25, 25, 25, 25, 25]
	var remaining = maxi(0, total - 150)
	var weights: Array = archetype.get("weights", [1, 1, 1, 1, 1, 1])

	for i in range(remaining):
		var idx = _weighted_index(weights)
		if points[idx] < 92:
			points[idx] += 1
	return points


func _weighted_index(weights: Array) -> int:
	var total = 0
	for w in weights:
		total += int(w)
	var roll = randi() % maxi(1, total)
	var acc = 0
	for i in range(weights.size()):
		acc += int(weights[i])
		if roll < acc:
			return i
	return 0


func _roll_archetype() -> Dictionary:
	var archetypes = [
		{"name": "剑修苗子", "weights": [4, 2, 1, 2, 1, 4], "skill": "crafting"},
		{"name": "丹道学徒", "weights": [1, 4, 2, 3, 2, 2], "skill": "alchemy"},
		{"name": "阵法童子", "weights": [1, 4, 2, 3, 1, 3], "skill": "formation"},
		{"name": "灵植药童", "weights": [2, 3, 3, 3, 2, 2], "skill": "medicine"},
		{"name": "驭兽少年", "weights": [3, 2, 2, 2, 3, 3], "skill": "beast_taming"},
		{"name": "符箓散学", "weights": [1, 4, 2, 2, 2, 3], "skill": "talisman"},
		{"name": "福缘游子", "weights": [2, 2, 5, 2, 3, 2], "skill": ""},
		{"name": "苦修之人", "weights": [3, 2, 1, 5, 1, 3], "skill": ""},
	]
	return archetypes[randi() % archetypes.size()]


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


func _make_origin_story(dname: String, gender: int, specialty: String, personalities: Array, quality: String) -> String:
	var hometowns = ["山下药镇", "边郡散修坊", "旧战场外村", "东海渡口", "北山猎户寨", "中州书院旁"]
	var incidents = {
		"剑修苗子": "曾以木剑护住同伴，虽受伤却不退半步",
		"丹道学徒": "在药铺帮工多年，能凭气味分辨几味常见灵草",
		"阵法童子": "幼时常在地上画阵纹，误打误撞引动过微弱灵光",
		"灵植药童": "照料过一小片灵田，对草木枯荣很敏感",
		"驭兽少年": "曾救下一只受伤灵兽，因此懂得几分兽性",
		"符箓散学": "临摹旧符纸多年，笔画虽稚嫩却很稳",
		"福缘游子": "一路漂泊却屡次逢凶化吉，像是被命数轻轻推着走",
		"苦修之人": "出身清贫，每日打坐不辍，靠极强耐性熬过最难的日子",
	}
	var root_note = {
		"heaven": "测灵时灵光纯净，几乎压过了测灵石的纹路",
		"variant": "灵根气息偏奇，似乎适合走少见路数",
		"true": "灵根根基尚正，是可以细心栽培的苗子",
		"false": "灵根驳杂，但若找到合适功法仍有前路",
		"waste": "灵根微弱，却偏偏不肯认命",
	}.get(quality, "灵根未明")
	var trait_text = "、".join(personalities) if not personalities.is_empty() else "性情未显"
	return "%s来自%s，%s。%s。入门初评为%s，性格偏%s。" % [
		dname,
		hometowns[randi() % hometowns.size()],
		incidents.get(specialty, "曾在坊市中表现出少见的定力"),
		root_note,
		specialty,
		trait_text,
	]


func _initial_loyalty(personalities: Array) -> int:
	var value = 52 + randi() % 13
	if "忠诚" in personalities:
		value += 14
	if "善良" in personalities or "豪爽" in personalities:
		value += 5
	if "贪婪" in personalities:
		value -= 10
	if "阴狠" in personalities or "孤傲" in personalities:
		value -= 7
	return clampi(value, 20, 95)
