extends Node
## 数据注册表 — 管理所有游戏数据定义（丹方、功法、设施模板等）


## 按 ID 索引的字典
var cultivation_realms: Dictionary = {}
var pill_recipes: Dictionary = {}
var craft_recipes: Dictionary = {}
var technique_templates: Dictionary = {}
var facility_templates: Dictionary = {}
var spirit_roots: Dictionary = {}
var event_templates: Dictionary = {}
var dungeon_templates: Dictionary = {}
var map_regions: Dictionary = {}
var world_lore: Dictionary = {}
var sect_positions: Dictionary = {}

## 加载状态
var _loaded: bool = false


func _ready() -> void:
	_load_all_data()


func _load_all_data() -> void:
	if _loaded:
		return

	_load_realms()
	_load_facilities()
	_load_spirit_roots()
	_load_recipes()
	_load_dungeons()
	_load_map_regions()
	_load_world_lore()
	_load_positions()
	_loaded = true


func _load_realms() -> void:
	cultivation_realms = {
		1: {"name": "练气", "sub_stages": 9, "lifespan": 120, "tribulation": "无"},
		2: {"name": "筑基", "sub_stages": 4, "lifespan": 250, "tribulation": "无"},
		3: {"name": "金丹", "sub_stages": 4, "lifespan": 500, "tribulation": "小天劫"},
		4: {"name": "元婴", "sub_stages": 4, "lifespan": 1000, "tribulation": "四九天劫"},
		5: {"name": "化神", "sub_stages": 4, "lifespan": 2000, "tribulation": "六九天劫"},
		6: {"name": "炼虚", "sub_stages": 4, "lifespan": 4000, "tribulation": "心魔劫"},
		7: {"name": "合体", "sub_stages": 4, "lifespan": 8000, "tribulation": "九九重劫"},
		8: {"name": "大乘", "sub_stages": 4, "lifespan": -1, "tribulation": "飞升劫"},
		9: {"name": "飞升", "sub_stages": 1, "lifespan": -1, "tribulation": "无"},
	}


func _load_facilities() -> void:
	facility_templates = {
		"cultivation_chamber": {
			"name": "修炼室",
			"max_level": 3,
			"build_cost": {1: 100, 2: 500, 3: 2000},
			"maintenance": {1: 5, 2: 20, 3: 50},  # 每月维护费（灵石）
			"cultivation_bonus": {1: 0.2, 2: 0.4, 3: 0.6},
			"capacity": {1: 3, 2: 6, 3: 10},  # 可容纳弟子数
		},
		"alchemy_hall": {
			"name": "丹药堂",
			"max_level": 3,
			"build_cost": {1: 200, 2: 800, 3: 3000},
			"maintenance": {1: 10, 2: 30, 3: 80},
			"alchemy_bonus": {1: 0.1, 2: 0.25, 3: 0.4},
		},
		"scripture_pavilion": {
			"name": "藏经阁",
			"max_level": 3,
			"build_cost": {1: 150, 2: 600, 3: 2500},
			"maintenance": {1: 8, 2: 25, 3: 60},
			"comprehension_bonus": {1: 0.1, 2: 0.2, 3: 0.35},
		},
		"arena": {
			"name": "演武场",
			"max_level": 3,
			"build_cost": {1: 120, 2: 550, 3: 2200},
			"maintenance": {1: 6, 2: 22, 3: 55},
			"combat_bonus": {1: 0.15, 2: 0.3, 3: 0.5},
		},
		"formation_hall": {
			"name": "阵法殿",
			"max_level": 3,
			"build_cost": {1: 300, 2: 1200, 3: 5000},
			"maintenance": {1: 15, 2: 50, 3: 120},
			"sect_defense": {1: 0.1, 2: 0.25, 3: 0.4},
		},
		"spirit_beast_garden": {
			"name": "灵兽园",
			"max_level": 3,
			"build_cost": {1: 250, 2: 1000, 3: 4000},
			"maintenance": {1: 12, 2: 40, 3: 100},
			"beast_training_bonus": {1: 0.1, 2: 0.25, 3: 0.4},
		},
		"spirit_field": {
			"name": "灵田",
			"max_level": 5,
			"build_cost": {1: 50, 2: 150, 3: 400, 4: 1000, 5: 2500},
			"herb_output": {1: 2, 2: 5, 3: 10, 4: 20, 5: 40},
		},
		"spirit_vein": {
			"name": "灵脉",
			"max_level": 5,
			"build_cost": {1: 500, 2: 2000, 3: 8000, 4: 30000, 5: 100000},
			"stone_output": {1: 25, 2: 60, 3: 150, 4: 350, 5: 800},
		},
		"medical_hall": {
			"name": "医馆",
			"max_level": 3,
			"build_cost": {1: 150, 2: 600, 3: 2500},
			"maintenance": {1: 8, 2: 25, 3: 60},
			"heal_rate": {1: 0.03, 2: 0.06, 3: 0.10},     # 每月恢复10%修为进度
			"life_extension": {1: 0, 2: 5, 3: 10},          # Lv.2+延长弟子寿元
		},
		"guest_quarters": {
			"name": "迎客居",
			"max_level": 3,
			"build_cost": {1: 100, 2: 400, 3: 1600},
			"maintenance": {1: 5, 2: 15, 3: 40},
			"recruit_quality_bonus": {1: 5, 2: 10, 3: 20},  # 招收弟子属性加成
		},
	}


func _load_spirit_roots() -> void:
	spirit_roots = {
		"heaven": {"name": "天灵根", "rarity": 0.005, "cultivation_mult": 2.0, "breakthrough_mult": 2.0, "element_count": 1},
		"variant": {"name": "异灵根", "rarity": 0.05, "cultivation_mult": 1.5, "breakthrough_mult": 1.5, "element_count": 2},
		"true": {"name": "真灵根", "rarity": 0.20, "cultivation_mult": 1.0, "breakthrough_mult": 1.0, "element_count": 3},
		"false": {"name": "伪灵根", "rarity": 0.45, "cultivation_mult": 0.6, "breakthrough_mult": 0.6, "element_count": 4},
		"waste": {"name": "废灵根", "rarity": 0.295, "cultivation_mult": 0.3, "breakthrough_mult": 0.3, "element_count": 5},
	}


func _load_recipes() -> void:
	pill_recipes = {
		"qi_gathering": {
			"name": "聚灵丹", "category": "cultivation",
			"materials": {"spirit_herb": 3},
			"base_success_rate": 0.7, "difficulty": 1, "craft_time": 1,
		},
		"foundation": {
			"name": "筑基丹", "category": "breakthrough",
			"materials": {"spirit_herb": 10, "ginseng": 2},
			"base_success_rate": 0.4, "difficulty": 3, "craft_time": 2,
		},
		"healing": {
			"name": "疗伤丹", "category": "recovery",
			"materials": {"spirit_herb": 2, "ginseng": 1},
			"base_success_rate": 0.75, "difficulty": 1, "craft_time": 1,
		},
		"fasting": {
			"name": "辟谷丹", "category": "utility",
			"materials": {"spirit_herb": 1},
			"base_success_rate": 0.9, "difficulty": 1, "craft_time": 1,
		},
		"spirit_focus": {
			"name": "凝神丹", "category": "cultivation",
			"materials": {"spirit_herb": 5, "ginseng": 1},
			"base_success_rate": 0.55, "difficulty": 2, "craft_time": 1,
		},
		"golden_core": {
			"name": "结金丹", "category": "breakthrough",
			"materials": {"spirit_herb": 30, "ginseng": 10, "lingzhi": 3},
			"base_success_rate": 0.25, "difficulty": 5, "craft_time": 3,
		},
	}

	craft_recipes = {
		"iron_sword": {
			"name": "青锋剑", "category": "weapon",
			"materials": {"iron": 5},
			"base_success_rate": 0.6, "difficulty": 1, "craft_time": 2,
		},
		"iron_armor": {
			"name": "玄铁甲", "category": "armor",
			"materials": {"iron": 8},
			"base_success_rate": 0.5, "difficulty": 2, "craft_time": 2,
		},
		"storage_bag": {
			"name": "储物袋", "category": "accessory",
			"materials": {"iron": 2, "silk": 3},
			"base_success_rate": 0.7, "difficulty": 1, "craft_time": 1,
		},
		"array_disk": {
			"name": "聚灵阵盘", "category": "accessory",
			"materials": {"iron": 10, "jade": 5},
			"base_success_rate": 0.35, "difficulty": 4, "craft_time": 3,
		},
	}

	# 加载初始材料种类（游戏启动后才执行）
	if GameManager.game_initialized and GameManager.current_sect:
		var sect = GameManager.current_sect
		if not sect.herbs.has("ginseng"):
			sect.herbs["ginseng"] = 0
		if not sect.herbs.has("lingzhi"):
			sect.herbs["lingzhi"] = 0
		if not sect.ores.has("silk"):
			sect.ores["silk"] = 0
		if not sect.ores.has("jade"):
			sect.ores["jade"] = 0


func get_realm_name(realm_id: int) -> String:
	return cultivation_realms.get(realm_id, {}).get("name", "未知")


func get_realm_sub_count(realm_id: int) -> int:
	return cultivation_realms.get(realm_id, {}).get("sub_stages", 1)


func _load_dungeons() -> void:
	dungeon_templates = {
		"spirit_mine": {
			"dungeon_name": "灵矿洞",
			"dungeon_type": "mine",
			"difficulty": 1, "danger_level": 15,
			"exploration_months": 1,
			"min_disciple_realm": 1, "min_disciple_count": 1, "max_disciple_count": 3,
			"cooldown_duration": 3,
			"description": "宗门附近一处废弃的灵石矿洞，深处偶尔还能挖到残存的灵石矿脉。",
			"loot_pool": [
				{"item_type": "spirit_stones", "weight": 60, "base_quantity": 50},
				{"item_type": "ore", "item_id": "iron", "weight": 40, "base_quantity": 5},
				{"item_type": "ore", "item_id": "jade", "weight": 10, "base_quantity": 1},
			],
			"event_pool": [],
		},
		"misty_valley": {
			"dungeon_name": "迷雾山谷",
			"dungeon_type": "secret_realm",
			"difficulty": 2, "danger_level": 30,
			"exploration_months": 2,
			"min_disciple_realm": 1, "min_disciple_count": 1, "max_disciple_count": 3,
			"cooldown_duration": 6,
			"description": "宗门后山深处一片常年被迷雾笼罩的山谷，据说偶尔能听到上古修士论道的声音。",
			"loot_pool": [
				{"item_type": "spirit_stones", "weight": 50, "base_quantity": 80},
				{"item_type": "herb", "item_id": "spirit_herb", "weight": 40, "base_quantity": 5},
				{"item_type": "herb", "item_id": "ginseng", "weight": 15, "base_quantity": 2},
				{"item_type": "technique_scroll", "weight": 5, "base_quantity": 1},
			],
			"event_pool": [
				{"id": "dungeon_ambush", "name": "妖兽伏击", "description": "迷雾中突然窜出一只妖兽！",
				 "choices": [{"label": "迎战", "effects": {"action": "combat_beast"}},
				             {"label": "撤退（损失进度）", "effects": {"action": "retreat_dungeon"}}]},
			],
		},
		"ancient_battlefield": {
			"dungeon_name": "古战场遗迹",
			"dungeon_type": "ancient_ruin",
			"difficulty": 4, "danger_level": 55,
			"exploration_months": 3,
			"min_disciple_realm": 2, "min_disciple_count": 2, "max_disciple_count": 4,
			"cooldown_duration": 12,
			"description": "千年前正魔大战的古战场，怨气不散、阴魂徘徊。废墟之下埋藏着不少遗落的法宝和功法残卷。",
			"loot_pool": [
				{"item_type": "spirit_stones", "weight": 40, "base_quantity": 200},
				{"item_type": "equipment", "item_id": "broken_sword", "weight": 25, "base_quantity": 1},
				{"item_type": "ore", "item_id": "jade", "weight": 20, "base_quantity": 3},
				{"item_type": "rare_material", "item_id": "soul_crystal", "weight": 10, "base_quantity": 1},
			],
			"event_pool": [
				{"id": "dungeon_wraith", "name": "阴魂缠身", "description": "古战场的怨魂感应到生人气息，向弟子们袭来！",
				 "choices": [{"label": "以修为硬抗", "effects": {"risk": "mentality_damage"}},
				             {"label": "念清心咒驱散", "effects": {"action": "cleanse_wraith"}}]},
			],
		},
		"demon_sealing_cave": {
			"dungeon_name": "封魔洞窟",
			"dungeon_type": "demon_cave",
			"difficulty": 6, "danger_level": 75,
			"exploration_months": 4,
			"min_disciple_realm": 3, "min_disciple_count": 3, "max_disciple_count": 5,
			"cooldown_duration": 18,
			"description": "上古大能封印大魔之地，封印渐弱、魔气外泄。正派宗门有责任定期巡视加固封印，也是获取珍稀魔核的唯一途径。",
			"loot_pool": [
				{"item_type": "spirit_stones", "weight": 30, "base_quantity": 500},
				{"item_type": "rare_material", "item_id": "demon_core", "weight": 20, "base_quantity": 1},
				{"item_type": "technique_scroll", "weight": 15, "base_quantity": 1},
				{"item_type": "prestige", "weight": 10, "base_quantity": 100},
			],
			"event_pool": [],
		},
	}


func _load_map_regions() -> void:
	map_regions = {}
	var regions_data = [
		# 行0
		{"id": "ice_plain", "name": "冰原", "grid_x": 0, "grid_y": 0, "terrain": "mountain", "spiritual_density": 30, "danger_level": 50, "description": "极北冰原，万里无人烟。传说有上古冰龙埋骨于此。", "special_locations": []},
		{"id": "north_mountain", "name": "北域雪山", "grid_x": 1, "grid_y": 0, "terrain": "mountain", "spiritual_density": 40, "danger_level": 40, "description": "终年积雪的北域山脉，隐藏着上古冰封秘境。", "special_locations": []},
		{"id": "dragon_vein", "name": "龙脉", "grid_x": 2, "grid_y": 0, "terrain": "mountain", "spiritual_density": 70, "danger_level": 35, "description": "天地灵脉汇聚之地，灵气浓郁。龙虎门立派于此，与万妖山争夺灵脉控制权。", "special_locations": ["spirit_mine"]},
		{"id": "myriad_beast_mt", "name": "万妖山", "grid_x": 3, "grid_y": 0, "terrain": "forest", "spiritual_density": 55, "danger_level": 60, "description": "万妖盘踞之地，妖兽横行。万妖山宗门驭兽为兵，实力不容小觑。", "special_locations": []},
		{"id": "east_sea", "name": "东海", "grid_x": 4, "grid_y": 0, "terrain": "river", "spiritual_density": 45, "danger_level": 30, "description": "浩瀚东海，水产丰饶。海底深处有龙宫遗迹的传说。", "special_locations": []},
		{"id": "penglai", "name": "蓬莱", "grid_x": 5, "grid_y": 0, "terrain": "river", "spiritual_density": 60, "danger_level": 25, "description": "东海仙岛，星辰阁所在。以阵法闻名天下，岛上四季如春。", "special_locations": ["misty_valley"]},
		# 行1
		{"id": "western_desert", "name": "荒漠", "grid_x": 0, "grid_y": 1, "terrain": "desert", "spiritual_density": 15, "danger_level": 45, "description": "西域大漠，灵气稀薄。沙漠深处有上古传送阵的遗迹。", "special_locations": []},
		{"id": "alliance_city", "name": "联盟城", "grid_x": 1, "grid_y": 1, "terrain": "plain", "spiritual_density": 50, "danger_level": 10, "description": "修真界的贸易中心，中立之地。坊市云集，各宗修士汇聚于此交易。", "special_locations": []},
		{"id": "central_plain", "name": "中州平原", "grid_x": 2, "grid_y": 1, "terrain": "plain", "spiritual_density": 60, "danger_level": 10, "description": "修真界的中心地带，灵气充沛，交通四通八达。正魔双方据此划定势力范围。", "special_locations": []},
		{"id": "qingyun_mt", "name": "青云山", "grid_x": 3, "grid_y": 1, "terrain": "mountain", "spiritual_density": 65, "danger_level": 20, "description": "青云门所在，山清水秀，灵气环绕。以剑道和丹道著称。", "special_locations": []},
		{"id": "east_forest", "name": "东方森林", "grid_x": 4, "grid_y": 1, "terrain": "forest", "spiritual_density": 50, "danger_level": 35, "description": "广袤的原始森林，灵草灵药遍地，但妖兽也随处可见。", "special_locations": ["spirit_mine"]},
		{"id": "biluo_sea", "name": "碧落海", "grid_x": 5, "grid_y": 1, "terrain": "river", "spiritual_density": 40, "danger_level": 30, "description": "碧落宗所在海域，宗门建于海岛上，以水系功法闻名。", "special_locations": []},
		# 行2
		{"id": "west_region", "name": "西域", "grid_x": 0, "grid_y": 2, "terrain": "desert", "spiritual_density": 20, "danger_level": 40, "description": "西域边陲，地广人稀。偶有商队穿越，偶有沙匪出没。", "special_locations": []},
		{"id": "danxia_valley", "name": "丹霞谷", "grid_x": 1, "grid_y": 2, "terrain": "plain", "spiritual_density": 55, "danger_level": 15, "description": "丹霞派所在，峡谷中遍布灵草。丹霞派以炼丹术闻名天下。", "special_locations": []},
		{"id": "player_home", "name": "宗门山门", "grid_x": 2, "grid_y": 2, "terrain": "mountain", "spiritual_density": 55, "danger_level": 10, "description": "本门山门所在。从一座破败山门起步，终将成为修真界巨擘。", "special_locations": ["spirit_mine", "misty_valley"]},
		{"id": "taixu_temple", "name": "太虚观", "grid_x": 3, "grid_y": 2, "terrain": "mountain", "spiritual_density": 60, "danger_level": 15, "description": "太虚观所在，道家清修之地。数百年来潜心修道，不问世事。", "special_locations": []},
		{"id": "star_pavilion", "name": "星辰阁", "grid_x": 4, "grid_y": 2, "terrain": "forest", "spiritual_density": 55, "danger_level": 25, "description": "星辰阁分阁所在地，以观星推演之术闻名。阁中藏有无数天机秘卷。", "special_locations": []},
		{"id": "south_sea", "name": "南海", "grid_x": 5, "grid_y": 2, "terrain": "river", "spiritual_density": 35, "danger_level": 35, "description": "南海诸岛，碧波万顷。水下暗流汹涌，有海兽出没。", "special_locations": []},
		# 行3
		{"id": "devil_abyss", "name": "魔渊", "grid_x": 0, "grid_y": 3, "terrain": "volcano", "spiritual_density": 30, "danger_level": 80, "description": "魔气汇聚之地，深渊之下封印着上古大魔。没有任何正道修士敢轻易踏足。", "special_locations": ["demon_sealing_cave"]},
		{"id": "blood_devil_sect", "name": "血魔谷", "grid_x": 1, "grid_y": 3, "terrain": "swamp", "spiritual_density": 35, "danger_level": 70, "description": "血魔宗山门。谷中血气弥漫，修炼邪功的魔修在此盘踞。", "special_locations": []},
		{"id": "south_border", "name": "南疆", "grid_x": 2, "grid_y": 3, "terrain": "swamp", "spiritual_density": 35, "danger_level": 50, "description": "南疆蛮荒之地，瘴气弥漫。但也是许多奇珍异草的唯一产地。", "special_locations": ["spirit_mine"]},
		{"id": "nether_hall", "name": "幽冥殿", "grid_x": 3, "grid_y": 3, "terrain": "volcano", "spiritual_density": 25, "danger_level": 75, "description": "幽冥殿所在，终年不见天日。殿主以冥界功法闻名魔道。", "special_locations": []},
		{"id": "myriad_beast_forest", "name": "万兽山", "grid_x": 4, "grid_y": 3, "terrain": "forest", "spiritual_density": 45, "danger_level": 60, "description": "妖兽丛生之地，万兽尊者在此统御百兽。", "special_locations": []},
		{"id": "south_barbarian", "name": "南蛮", "grid_x": 5, "grid_y": 3, "terrain": "forest", "spiritual_density": 30, "danger_level": 50, "description": "南蛮部落聚居地，与修真界语言不通。据说部落中传承着独特的体修功法。", "special_locations": []},
		# 行4
		{"id": "death_land", "name": "死地", "grid_x": 0, "grid_y": 4, "terrain": "desert", "spiritual_density": 5, "danger_level": 90, "description": "生命禁区，灵气枯竭。没有任何宗门能在此生存。", "special_locations": []},
		{"id": "ancient_battlefield", "name": "古战场", "grid_x": 1, "grid_y": 4, "terrain": "desert", "spiritual_density": 20, "danger_level": 60, "description": "千年前正魔大战的决战之地。残剑断戟随处可见，怨魂徘徊不散。", "special_locations": ["ancient_battlefield", "demon_sealing_cave"]},
		{"id": "sealing_cave", "name": "封魔洞", "grid_x": 2, "grid_y": 4, "terrain": "volcano", "spiritual_density": 15, "danger_level": 80, "description": "上古封魔之地，洞中封印松动，魔气外泄。需金丹期以上方可探索。", "special_locations": ["demon_sealing_cave"]},
		{"id": "spirit_vein_mt", "name": "灵矿脉", "grid_x": 3, "grid_y": 4, "terrain": "mountain", "spiritual_density": 50, "danger_level": 30, "description": "灵石矿脉富集的山脉，灵矿洞遍布。各大宗门争夺的宝地。", "special_locations": ["spirit_mine"]},
		{"id": "misty_valley_loc", "name": "迷雾谷", "grid_x": 4, "grid_y": 4, "terrain": "forest", "spiritual_density": 45, "danger_level": 35, "description": "常年云雾缭绕的谷地。迷雾中含有特殊灵气，对修炼有奇效。", "special_locations": ["misty_valley"]},
		{"id": "sky_edge", "name": "天涯", "grid_x": 5, "grid_y": 4, "terrain": "river", "spiritual_density": 30, "danger_level": 55, "description": "大陆的尽头，天海相接。偶有飞升者从此处踏入仙界。", "special_locations": []},
	]
	for r in regions_data:
		map_regions[r["id"]] = r


func _load_world_lore() -> void:
	world_lore = {
		"creation_01": {
			"category": "创世神话", "title": "混沌开天", "era_tag": 0,
			"content": "太古之初，天地未分，混沌如鸡子。盘古大神以开天神斧劈开混沌，清气上升为天，浊气下沉为地。盘古身化万物：左眼为日，右眼为月，血脉为江河，筋骨为山脉，元神化为天地间第一缕灵气，是为修仙之源。",
			"unlock_condition": "default",
		},
		"creation_02": {
			"category": "创世神话", "title": "三千大道", "era_tag": 0,
			"content": "盘古陨落后，其修炼感悟化作三千大道法则散落天地。后世修士参悟大道碎片，创出修仙法门。有人修剑道斩妖除魔，有人修丹道济世救人，有人修阵法御敌于千里之外——万法归宗，皆源于此。",
			"unlock_condition": "default",
		},
		"creation_03": {
			"category": "创世神话", "title": "仙魔初分", "era_tag": 1,
			"content": "上古时期，第一批修士登临飞升之境。然飞升之路并非坦途——有人顺应天道，以功德飞升；有人逆天而行，以杀伐证道。前者被后世称为「仙」，后者被后世称为「魔」。仙魔之争，自此而始。",
			"unlock_condition": "default",
		},
		"era_01": {
			"category": "当前纪元", "title": "宗门历纪元", "era_tag": 4,
			"content": "三千年前，正道七宗与魔道五宗签订「苍梧之约」，结束持续万年的正魔大战。约定以「宗门历」为共同时历，以中州平原为中立之地，正魔双方各自退守一方。此约签订之日，定为一宗门历元年。自此修真界进入宗门林立的战国时代。",
			"unlock_condition": "default",
		},
		"era_02": {
			"category": "当前纪元", "title": "诸宗并起", "era_tag": 4,
			"content": "苍梧之约后，修真界休养生息千年。各大宗门如雨后春笋般涌现——天剑宗以剑道称雄，血魔宗以魔功逞威，丹霞派以丹药济世，万花谷以医术闻名。宗门历三千年，正值修真界又一黄金盛世，也是群雄逐鹿的大争之世。而你的宗门，才刚刚起步……",
			"unlock_condition": "default",
		},
		"era_03": {
			"category": "当前纪元", "title": "暗流涌动", "era_tag": 4,
			"content": "和平的表面下暗流涌动。魔道势力暗中扩张，正道宗门貌合神离。更可怕的是，上古封印隐隐有松动迹象——封魔洞窟的魔气日益浓郁，古战场的怨魂愈发狂暴。有占星者预言，一场席卷三界的大劫即将来临……",
			"unlock_condition": "default",
		},
		"faction_01": {
			"category": "势力来历", "title": "天剑宗", "era_tag": 3,
			"content": "天剑宗始祖「剑尊」独孤一剑，近古时期在中州平原悟道，以一剑破万法、开创天剑宗。宗门以剑为正道之首，历代宗主皆以剑入道。当代宗主已臻至金丹后期，为天下剑修第一人。天剑宗秉持「以剑正道、斩妖除魔」的宗旨，是正道联盟的首领。",
			"unlock_condition": "default",
		},
		"faction_02": {
			"category": "势力来历", "title": "万花谷", "era_tag": 3,
			"content": "万花谷由医仙花弄月创建。传说花弄月为救挚爱踏遍天下寻药，最终在万花谷中参悟医道至理。万花谷不以战力见长，但天下丹药十之七八出自此地。谷中弟子皆有高超医术，正魔两道都对万花谷礼让三分。",
			"unlock_condition": "default",
		},
		"faction_03": {
			"category": "势力来历", "title": "血魔宗", "era_tag": 3,
			"content": "血魔宗是魔道第一大宗，创始者血魔老祖原为散修，在一次遗迹探索中得到上古魔功残卷，从此走上魔道。他以血炼之法速成，百年内踏入化神之境。血魔宗以「强者为尊」为铁律，对内残酷竞争，对外悍不畏死。",
			"unlock_condition": "default",
		},
		"faction_04": {
			"category": "势力来历", "title": "幽冥殿", "era_tag": 3,
			"content": "幽冥殿源自上古冥界传承。殿下深通幽冥之术，能以生魂炼器、以怨气修炼。虽然被正道斥为邪魔外道，但幽冥殿中人也遵循着「不杀凡人、不屠无辜」的底线。他们更多是在亡者身上做文章，而非滥杀。",
			"unlock_condition": "default",
		},
		"faction_05": {
			"category": "势力来历", "title": "炼器宗", "era_tag": 3,
			"content": "炼器宗由匠神欧冶子创立，自称「天下法宝出炼器」。宗门以炼器术傲视修真界，无论是飞剑、铠甲还是阵盘，炼器宗所出皆为上品。宗门与丹霞派世代交好，一方出丹、一方出器，互为倚仗。",
			"unlock_condition": "default",
		},
		"faction_06": {
			"category": "势力来历", "title": "丹霞派", "era_tag": 3,
			"content": "丹霞派坐落于丹霞谷中，谷中遍布奇珍灵草。开派祖师丹阳真人留下「以丹济世、普度众生」的门训。丹霞派弟子精通丹道，所炼丹药品质上乘，为各大宗门所争相求购。",
			"unlock_condition": "default",
		},
		"geography_01": {
			"category": "天下地理", "title": "中州风云", "era_tag": 4,
			"content": "中州平原是修真界的中心。这里灵气充沛、四通八达，是所有大宗门的必争之地。天剑宗、太虚观、青云门皆在此附近立派。联盟城更是天下修士汇聚交易的中心。控制中州者，得天下。",
			"unlock_condition": "default",
		},
		"geography_02": {
			"category": "天下地理", "title": "魔域深渊", "era_tag": 4,
			"content": "大陆西南的魔渊和血魔谷是魔道势力的核心地带。终年魔气弥漫、寸草不生。但这里也产出修真界最珍贵的魔核——一种只能从魔化生物身上获取的稀有材料。越危险的地方，机遇越大。",
			"unlock_condition": "default",
		},
		"geography_03": {
			"category": "天下地理", "title": "北境秘境", "era_tag": 4,
			"content": "极北冰原虽灵气稀薄、环境恶劣，却隐藏着无数上古秘境。据说上古修士为躲避战乱，将洞府和宝物封印于极北冰层之下。万妖山和龙虎门常年在此探索，偶有所获，震慑天下。",
			"unlock_condition": "explore_dungeon:misty_valley",
		},
		"geography_04": {
			"category": "天下地理", "title": "东海仙岛", "era_tag": 4,
			"content": "东海之上散落着无数仙岛。蓬莱仙岛、碧落海阁、星辰阁皆坐落于东海。岛上灵气浓郁、四季如春，是修士梦寐以求的修炼宝地。但深海之下暗藏危机——上古海兽的巢穴就在东海深处。",
			"unlock_condition": "default",
		},
		"geography_05": {
			"category": "天下地理", "title": "古战场秘闻", "era_tag": 4,
			"content": "千年前的正魔大决战发生在今日的西南荒漠。那一战打得天昏地暗，方圆千里化为焦土。战后，无数法宝、功法散落于战场废墟之中。数百年来，寻宝者络绎不绝，但据说最珍贵的宝物至今未被发现——它藏于古战场深处，被万年怨魂守护着。",
			"unlock_condition": "explore_dungeon:ancient_battlefield",
		},
	}


func _load_positions() -> void:
	sect_positions = {
		"副掌门": {"salary": 30, "min_realm": 3, "rank_unlock": 4, "max_count": 1, "bonus": "cultivation_boost", "bonus_value": 0.15, "description": "协助掌门管理宗门事务"},
		"长老": {"salary": 20, "min_realm": 2, "rank_unlock": 8, "max_count": 2, "bonus": "teaching_boost", "bonus_value": 0.10, "description": "指导弟子修炼，传授功法"},
		"护法": {"salary": 10, "min_realm": 1, "rank_unlock": 7, "max_count": 2, "bonus": "defense_boost", "bonus_value": 0.10, "description": "守护山门，抵御外敌"},
		"执事": {"salary": 5, "min_realm": 1, "rank_unlock": 9, "max_count": 3, "bonus": "efficiency_boost", "bonus_value": 0.05, "description": "管理日常事务，协调资源分配"},
		"普通弟子": {"salary": 0, "min_realm": 0, "rank_unlock": 9, "max_count": 99, "bonus": "none", "bonus_value": 0.0, "description": "宗门基层弟子"},
	}


func get_terrain_color(terrain: String) -> Color:
	var colors = {
		"plain": Color(0.35, 0.50, 0.20),
		"mountain": Color(0.45, 0.40, 0.35),
		"forest": Color(0.15, 0.40, 0.15),
		"desert": Color(0.55, 0.50, 0.30),
		"river": Color(0.20, 0.35, 0.55),
		"swamp": Color(0.25, 0.35, 0.20),
		"volcano": Color(0.50, 0.20, 0.10),
	}
	return colors.get(terrain, Color.GRAY)


func get_terrain_icon(terrain: String) -> String:
	var icons = {
		"plain": "田", "mountain": "山", "forest": "林",
		"desert": "沙", "river": "水", "swamp": "泽", "volcano": "火",
	}
	return icons.get(terrain, "·")
