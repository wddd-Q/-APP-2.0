extends Node
## 世界控制器

const FactionData = preload("res://src/core/data/faction_data.gd")


var npc_factions: Array = []
var world_events: Array[Dictionary] = []
var region_control: Dictionary = {}  # {region_id: faction_name}


func _ready() -> void:
	_initialize_npc_factions()


func process_npc_turn() -> void:
	"""每年调用一次，所有 NPC 宗门执行 AI"""
	for faction in npc_factions:
		if not faction.is_alive:
			continue
		_npc_annual_decision(faction)
	_update_region_control()


func _npc_annual_decision(sect: FactionData) -> void:
	# 1. 资源结算
	sect.spirit_stones += _calculate_npc_income(sect)

	# 2. 检查突破
	var candidates = _get_npc_breakthrough_candidates(sect)
	if not candidates.is_empty():
		# NPC修炼推进
		sect.combat_power += int(sect.combat_power * 0.05 * (randf() + 0.5))

	# 3. 威胁评估
	var threat_level = _assess_threat(sect)

	# 4. 决策
	if threat_level > sect.combat_power * 0.7:
		_npc_seek_alliance(sect)
	elif sect.aggression > 50 and _has_expansion_target(sect):
		_npc_consider_war(sect)
	elif sect.spirit_stones > 1000:
		_npc_expand(sect)
	else:
		_npc_cultivate(sect)


func _calculate_npc_income(sect: FactionData) -> int:
	return sect.controlled_veins.size() * 20


func _get_npc_breakthrough_candidates(sect: FactionData) -> Array:
	# 简化：随机是否有弟子突破
	return [] if randf() > 0.1 else [{"realm": sect.faction_realm + 1}]


func _assess_threat(sect: FactionData) -> int:
	var max_threat = 0
	for other in npc_factions:
		if other == sect or not other.is_alive:
			continue
		if other.relation_to_player < -60:  # 死敌关系
			max_threat = maxi(max_threat, other.combat_power)
	return max_threat


func _has_expansion_target(sect: FactionData) -> bool:
	return npc_factions.any(func(f): return f.is_alive and f != sect)


func _npc_seek_alliance(sect: FactionData) -> void:
	if sect.diplomacy < 30:
		return
	# 寻找最友好的势力结盟: 找到关系值最高的且未达同盟级别的
	var best_target: FactionData = null
	var best_relation = -999
	for other in npc_factions:
		if other == sect or not other.is_alive:
			continue
		# 模拟关系值: 相同阵营更友好
		var rel = 50 if (sect.karma > 0) == (other.karma > 0) else -20
		rel += randi() % 41 - 20  # 随机波动
		if rel > best_relation and rel < 60:
			best_relation = rel
			best_target = other

	if best_target:
		sect.relation_to_player += 5
		# 产生世界消息 (future: EventBus emit)


func _npc_consider_war(sect: FactionData) -> void:
	# 找到战力低于自己且关系差的势力
	for target in npc_factions:
		if target == sect or not target.is_alive:
			continue
		if target.combat_power < sect.combat_power * 0.7:
			var is_enemy = (sect.karma > 0) != (target.karma > 0)
			if is_enemy or randi() % 100 < sect.aggression:
				# 宣战
				var result = CombatController.simulate_battle(
					sect.faction_name, target.faction_name, sect, target
				)
				if result.attacker_won:
					sect.combat_power -= result.attacker_losses
					target.combat_power -= result.defender_losses
					if target.combat_power <= 0:
						target.is_alive = false
				return  # 每回合只打一场


func _npc_expand(sect: FactionData) -> void:
	# 建造设施 / 升级灵脉
	sect.spirit_stones -= 500
	sect.combat_power += 15
	if sect.controlled_veins.size() < 3:
		sect.controlled_veins.append("vein_%s_%d" % [sect.faction_name, sect.controlled_veins.size()])


func _npc_cultivate(sect: FactionData) -> void:
	var growth = int(sect.combat_power * 0.03 * (randf() * 0.5 + 0.5))
	sect.combat_power += growth


func _update_region_control() -> void:
	region_control.clear()
	for faction in npc_factions:
		if not faction.is_alive:
			continue
		if faction.home_region == "":
			continue
		region_control[faction.home_region] = faction.faction_name
	region_control["player_home"] = "本门"


func get_region_controller(region_id: String) -> String:
	return region_control.get(region_id, "")


func _initialize_npc_factions() -> void:
	var names = [
		"天剑宗", "万花谷", "炼器宗", "丹霞派",
		"血魔宗", "幽冥殿", "万妖山", "龙虎门",
		"太虚观", "青云门", "碧落宗", "星辰阁",
	]
	var home_regions = [
		"central_plain", "east_forest", "star_pavilion", "danxia_valley",
		"blood_devil_sect", "nether_hall", "myriad_beast_mt", "dragon_vein",
		"taixu_temple", "qingyun_mt", "biluo_sea", "penglai",
	]

	for i in range(names.size()):
		var faction = FactionData.new()
		faction.faction_name = names[i]
		faction.faction_rank = randi() % 5 + 4
		faction.faction_realm = randi() % 3 + 2
		faction.prestige = randi() % 500
		faction.spirit_stones = randi() % 2000 + 500
		faction.combat_power = (faction.faction_realm * faction.faction_realm) * 100 + randi() % 500
		faction.aggression = randi() % 100
		faction.diplomacy = randi() % 100
		faction.development_priority = randi() % 100
		faction.loyalty = randi() % 100
		faction.relation_to_player = randi() % 41 - 20
		faction.home_region = home_regions[i]

		if i < 6:
			faction.karma = randi() % 51 + 20
		elif i < 10:
			faction.karma = -(randi() % 51 + 20)
		else:
			faction.karma = randi() % 41 - 20

		_generate_npc_disciples(faction)

		npc_factions.append(faction)

	_update_region_control()


func _generate_npc_disciples(faction: FactionData) -> void:
	const NameGenerator = preload("res://src/core/systems/name_generator.gd")
	var count = 3 + randi() % 5
	var surnames = ["赵", "钱", "孙", "李", "周", "吴", "郑", "王", "冯", "陈", "褚", "卫",
		"蒋", "沈", "韩", "杨", "朱", "秦", "许", "何", "吕", "张", "孔", "曹", "严", "华"]
	var given_names = ["天", "云", "风", "雷", "雨", "雪", "霜", "尘", "无极", "道远",
		"子轩", "浩然", "逸飞", "明哲", "青云", "鸿飞", "长风", "月华", "星辰", "行舟"]

	var root_qualities = ["true", "true", "true", "false", "false", "variant", "waste", "heaven"]
	var root_names = {"heaven": "天灵根", "variant": "异灵根", "true": "真灵根", "false": "伪灵根", "waste": "废灵根"}
	var personalities_pool = ["勇猛", "谨慎", "贪婪", "忠诚", "孤傲", "好奇", "善良", "阴狠", "豪爽", "内敛"]

	for _i in range(count):
		var gender = randi() % 2
		var surname = surnames[randi() % surnames.size()]
		var gname = given_names[randi() % given_names.size()]
		if gender == 1 and randi() % 2 == 0:
			gname = ["月", "雪", "瑶", "仙", "灵", "青", "婉", "慧", "兰", "霜"][randi() % 10]

		var root_quality = root_qualities[randi() % root_qualities.size()]
		var elements = []
		var elem_count = randi() % 5 + 1
		for _j in range(elem_count):
			var elem = randi() % 5
			if not elements.has(elem):
				elements.append(elem)

		var realm = 1 + randi() % faction.faction_realm
		var sub_realm = 1 + randi() % 9
		var base_attr = 30 + realm * 10 + randi() % 30

		faction.disciples.append({
			"name": surname + gname,
			"gender": gender,
			"age": 18 + randi() % (40 + realm * 20),
			"realm": realm,
			"sub_realm": sub_realm,
			"bone_structure": base_attr + randi() % 20 - 10,
			"comprehension": base_attr + randi() % 20 - 10,
			"fortune": base_attr + randi() % 20 - 10,
			"mentality": base_attr + randi() % 20 - 10,
			"charm": base_attr + randi() % 20 - 10,
			"talent": base_attr + randi() % 20 - 10,
			"spirit_root_quality": root_quality,
			"spirit_root_name": root_names.get(root_quality, "?灵根"),
			"spirit_elements": elements,
			"personalities": [personalities_pool[randi() % personalities_pool.size()], personalities_pool[randi() % personalities_pool.size()]],
			"position": _get_npc_position(realm),
		})


func _get_npc_position(realm: int) -> String:
	if realm >= 7: return "老祖"
	if realm >= 6: return "宗主"
	if realm >= 5: return "副宗主"
	if realm >= 4: return "长老"
	if realm >= 3: return "护法"
	if realm >= 2: return "执事"
	return "弟子"
